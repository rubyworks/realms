require 'fileutils'
require 'roll/xdg'
require 'roll/library/ledger'

module Roll

  # Copy the original $LOAD_PATH, for use by specified "ruby: ..." loads.
  #$RUBY_PATH = $LOAD_PATH.dup

  class Library

    # VersionError is raised when a requested version cannot be found.
    class VersionError < ::RangeError  # :nodoc:
    end

    # VersionConflict is raised when selecting another version
    # of a library when a previous version has already been selected.
    class VersionConflict < ::LoadError  # :nodoc:
    end

    # = Library Manager
    # This is not instantiated by end-users, in fact normally it is singleton.
    # Rather it is accessded via delegation though the Library Metaclass.
    class Manager

      #
      attr :ledger

      #
      attr :locations

      # Setup library system.
      #
      def initialize
        @ledger    = {}
        @locations = []
        # Add Ruby's core and standard libraries to the ledger.
        #@ledger['ruby'] = Library.new(
        #  Library.rubylibdir,
        #  :name=>'ruby',
        #  :version=>RUBY_VERSION,
        #  :libpath=>Library.ruby_path
        #)
        ledger_files.each do |file|
          locs = File.read(file).split(/\s*\n/)
          locations.concat(locs)
        end
        load_projects(*locations)
      end

      #
      def ledger_files
        @ledger_files ||= XDG.config_select('roll/ledger.list')
      end

      # TODO: config or share is the proper directory?
      def system_ledger_file
        @system_ledger_file ||= File.join(XDG.config_dirs.first, 'roll/ledger.list')
      end

      #
      def user_ledger_file
        @user_ledger_file ||= File.join(XDG.config_home, 'roll/ledger.list')
      end

      # TODO: Make a more robust ledger loader
      def system_ledger
        @system_ledger ||= Ledger.new(system_ledger_file)
      end

      #
      #def save_system_ledger(list)
      #  FileUtils.mkdir_p(File.dirname(system_ledger_file))
      #  File.open(system_ledger_file, 'wb') do |f|
      #    f << list.join("\n")
      #  end
      #end

      # TODO: Make a more robust ledger loader
      def user_ledger
        @user_ledger ||= Ledger.new(user_ledger_file)
        #File.file?(user_ledger_file) ? File.read(user_ledger_file).split(/\s*\n/) : []
      end

      # Return a list of library names.
      def list
        ledger.keys
      end

      # TODO: load_path
      def load_projects(*locations)
        locations.each do |location|
          begin
            metadata = load_version(location)
            metadata[:location] = location
            metadata[:loadpath] = load_loadpath(location)

            lib = Library.new(metadata)
            #lib = Library.new(location, metadata)

            name = lib.name.downcase

            @ledger[name] ||= []
            @ledger[name] << lib

            @locations << location
          rescue => e
            raise e if ENV['ROLL_DEBUG'] or $DEBUG
            warn "scan error, library omitted -- #{location}" if ENV['ROLL_WARN'] or $VERBOSE
          end
        end
      end

      # Load and parse version stamp file.
      def load_version(location)
        patt = File.join(location,'VERSION')
        file = Dir.glob(patt, File::FNM_CASEFOLD).first
        if file
          parse_version_stamp(File.read(file))
        else
          {}
        end
      end

      # Wish there was a way to do this without using a
      # configuration file.
      def load_loadpath(location)
        file = File.join(location, 'meta', 'loadpath')
        if File.file?(file)
          paths = File.read(file).gsub(/\n\s*\n/m,"")
          paths = paths.split(/\s*\n/)
        else
          paths = ['lib']
        end
      end

      # Parse version stamp into it's various parts.
      def parse_version_stamp(text)
        #info, *libpath = *data.split(/\s*\n\s*/)
        name, version, status, date = *text.split(/\s+/)
        version = Version.new(version)
        date    = Time.mktime(*date.scan(/[0-9]+/))
        #default = default || "../#{name}"
        return {:name => name, :version => version, :status => status, :date => date}
      end

      # Get an instance of a library by name. Libraries are singleton, so once loaded
      # the same object is always returned.
      def instance(name, constraint=nil)
        name = name.to_s

        #raise "no library -- #{name}" unless ledger.include?( name )
        return nil unless ledger.include?(name)

        library = ledger[name]

        if Library===library
          if constraint
            raise VersionConflict, "previously selected version -- #{ledger[name].version}"
          else
            library
          end
        else # library is an array of versions
          if constraint
            compare = Version.constrant_lambda(constraint)
            version = library.select(&compare).max
          else
            version = library.max
          end
          unless version
            raise VersionError, "no library version -- #{name} #{constraint}"
          end
# DIFFERENCE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#          version.activate
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          ledger[name] = version
        end
      end

      # A shortcut for #instance.
      alias_method :[], :instance

      # Same as #instance but will raise and error if the library is not found.
      # This can also take a block to yield on the library.
      def open(name, constraint=nil, &yld)
        lib = instance(name, constraint)
        unless lib
          raise LoadError, "no library -- #{name}"
        end
        yield(lib) if yld
        lib
      end

      # Dynamic link extension.
      #
      def dlext
        @dlext ||= '.' + ::Config::CONFIG['DLEXT']
      end

      # Standard load path. This is where all "used" libs
      # a located.
      def load_path ; $LOAD_PATH ; end

      # Location of Ruby's core/standard libraries.
      def ruby_path ; $RUBY_PATH ; end

      # The main ruby lib dir (usually /usr/lib/ruby).
      def rubylibdir
        ::Config::CONFIG['rubylibdir']
      end

      # Load stack stores a list of libraries, where the one
      # on top of the stack is the one current loading.
      def load_stack
        @load_stack ||= []
      end

      # The current library.
      def last
        load_stack.last
      end

      # Rolls requires a modification to #require and #load.
      # So that it is not neccessary to make the library() call
      # if you just want the latest version.
      #
      # This would be a bit simpler if we mandated the
      # use of the ':' notation when specifying the library
      # name. Use of the ':' is robust. But we cannot do this
      # w/o loosing backward-compatability. Using '/' in its
      # place has a slight potential for pathname clashing, albeit
      # the likelihood is small. There are two ways to bypass
      # the problem if it arises. Use 'ruby:{path}' if the
      # conflicting lib is a ruby core or standard library.
      # Use ':{path}' to bypass Roll system altogether.
      #
      # FIXME This doesn;t work for autoload. This is really
      # a bug in Ruby b/c autoload is not using the overriden
      # require.
      #
      #alias_method :require_without_roll, :require
      #public :require_without_roll

      #alias_method :load_without_roll, :load
      #public :load_without_roll

      # Require
      #
      def require(file)
        # specific library
        if file.index(':')
          name, path = file.split(':')
          lib = Library.instance(name)
          raise LoadError, "no library found -- #{file}" unless lib
          lib.require(path)
        else
          # potential specified library
          # ie. head of path is library name
          name, *rest = file.split(/[\\\/]/)
          path = File.join(*rest)
          path = nil if path.empty?

          if lib = instance(name)
            begin
              return lib.require(path)
            rescue LoadError => load_error
              raise load_error if ENV['ROLL_DEBUG']
            end
          end

          # try Ruby core/standandard library
          # actually just traditional require
          # (allowing other load hacks to work, including RubyGems)
          begin
            return Kernel.require(file)
          rescue LoadError => kernel_error
            raise kernel_error if ENV['ROLL_DEBUG']
          end

          # try current library
          if lib = load_stack.last
            begin
              return lib.require(file)
            rescue LoadError => load_error
              raise load_error if ENV['ROLL_DEBUG']
            end
          end

          raise kernel_error # failure
        end
      end

      #
      def load(file, wrap=false)
        # specific library
        if file.index(':')
          name, path = file.split(':')
          lib = Library.instance(name)
          raise LoadError, "no library found -- #{file}" unless lib
          lib.load(path, wrap)
        else
          # potentialy specified library,
          # ie. head of path is library name
          name, *rest = file.split(/[\\\/]/)
          path = File.join(*rest)
          path = nil if path.empty?
          if lib = instance(name)
            begin
              return lib.load(path, wrap)
            rescue LoadError => load_error
              raise load_error if ENV['ROLL_DEBUG']
            end
          end

          # try Ruby core/standard library
          # actually just traditional load
          # (allowing other load hacks to work, including RubyGems)
          begin
            return Kernel.load(file, wrap)
          rescue LoadError => kernel_error
            raise kernel_error if ENV['ROLL_DEBUG']
          end

          # try current library
          if lib = load_stack.last
            begin
              return lib.load(file, wrap)
            rescue LoadError => load_error
              raise load_error if ENV['ROLL_DEBUG']
            end
          end
        end

        raise kernel_error # failure
      end

=begin
      # Require script.
      #
      # NOTE: Ideally this would first look for a specific library 
      #       via ':', and then try the current library. Failing
      #       that it would fall back to Ruby itself. However this
      #       would break compatibility.
      #
      def require(file)
        # specific library
        if file.index(':')
          name, path = file.split(':')
          lib = Library.instance(name)
          raise LoadError, "no library found -- #{name}" unless lib
          return lib.require(path)
        end

        load_error = nil

        # potential specified library, ie. head of path is library name
        name, *rest = file.split('/')
        path = File.join(*rest)
        path = nil if path.empty?
        if lib = Library.instance(name)
          begin
            return lib.require(path)
          rescue LoadError => load_error
            #raise load_error if ENV['ROLL_DEBUG']
          end
        end

        # traditional attempt (allows other load hacks to work, including RubyGems)
        begin
          return Kernel.require(file)
        rescue LoadError => kernel_error
          raise load_error if load_error
          raise kernel_error
        end

        # failure
        #raise kernel_error
      end

      # Load script.
      def load(file, wrap=false)
        # specific library
        if file.index(':')
          name, path = file.split(':')
          lib = Library.instance(name)
          raise LoadError, "no library found -- #{file}" unless lib
          return lib.load(path, wrap)
        end

        load_error = nil

        # potential specified library, ie. head of path is library name
        name, *rest = file.split('/')
        path = File.join(*rest)
        if lib = Library.instance(name)
          begin
            return lib.load(path, wrap)
          rescue LoadError => load_error
            #raise load_error if ENV['ROLL_DEBUG']
          end
        end

        # traditional attempt (allows other load hacks to work, including RubyGems)
        begin
          return Kernel.load(file, wrap)
        rescue LoadError => kernel_error
          raise load_error if load_error
          raise kernel_error
        end

        # failure
        #raise kernel_error
      end
=end

    private

      #
      def parse_load_parameters(file)
        if must = file.index(':')
          name, path = file.split(':')
        else
          name, *rest = file.split('/')
          path = File.join(*rest)
        end
        name = nil if name == ''
        if name
          lib = Library.instance(name)
        else
          lib = nil
        end
        raise LoadError, "no library found -- #{file}" if must && !lib
        return lib, path, must
      end

    end #class Manager

  end #class Library

end #module Roll

