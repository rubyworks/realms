require 'fileutils'
require 'roll/xdg'
require 'roll/library/ledger'

module Roll

  # Copy the original $LOAD_PATH, for use by specified "ruby: ..." loads.
  #$RUBY_PATH = $LOAD_PATH.dup

  # TODO: Ledger loader (ie. Ledger.new) could be more robust?

  class Library

    # = Library Management
    #
    # The Management module extends Library.
    #
    module Management

      #
      attr :ledger_files

      #
      attr :system_ledger_file

      #
      attr :user_ledger_file

      #
      attr :system_ledger

      #
      attr :user_ledger

      # Setup library system.
      #
      def setup
        # Add Ruby's core and standard libraries to the ledger.
        #@ledger['ruby'] = Library.new(
        #  Library.rubylibdir,
        #  :name=>'ruby',
        #  :version=>RUBY_VERSION,
        #  :libpath=>Library.ruby_path
        #)

        @ledger             = {}
        @ledger_files       = XDG.config_select('roll/ledger.list')

        @system_ledger_file = File.join(XDG.config_dirs.first, 'roll/ledger.list')
        @system_ledger      = Ledger.new(@system_ledger_file)

        @user_ledger_file   = File.join(XDG.config_home, 'roll/ledger.list')
        @user_ledger        = Ledger.new(@user_ledger_file)

        @lookup = []

        #load_locations
        load_projects
      end

      #
      def ledger
        @ledger ||= {}
      end

      #
      #def locations
      #  @location ||= []
      #end

      #
      def locations
        @locations ||= (
          locs = []
          ledger_files.each do |file|
            File.readlines(file).each do |line|
              next if line =~ /^\s*$/
              dir, depth = *line.strip.split(/\s+/)
              locs << find_projects(dir, depth)
            end
          end
          locs.flatten
        )
      end

      #
      #def save_system_ledger(list)
      #  FileUtils.mkdir_p(File.dirname(system_ledger_file))
      #  File.open(system_ledger_file, 'wb') do |f|
      #    f << list.join("\n")
      #  end
      #end

      attr :lookup

      # Return a list of library names.
      def list
        ledger.keys
      end

      # Search a given directory for projects upto a given depth.
      # Projects directories are determined by containing a
      # 'meta' or '.meta' directory.
      def find_projects(dir, depth=3)
        depth = Integer(depth || 3)
        depth = (0...depth).map{ |i| (["*"] * i).join('/') }.join(',')
        glob = File.join(dir, "{#{depth}}", "{.meta,meta}")
        meta_locations = Dir[glob]
        meta_locations.map{ |d| d.chomp('/meta').chomp('/.meta') }
      end

      # Load projects into ledger.
      #
      # TODO: load_path?
      #
      def load_projects
        locations.each do |location|
          begin
            lib = Library.new(location)
            name = lib.package.downcase
            ledger[name] ||= []
            ledger[name] << lib
            lib.loadpath.each do |path|
              @lookup << [File.join(lib.package, path), lib]
            end
          rescue NameError => e
            warn e if debug?
            warn "scan error, library omitted -- #{location}" if warn?
          end
        end
        # Sort lookup by version to ensure newest versions are found first.
        @lookup.sort!{ |a,b| b[1].version <=> a[1].version }
      end

      # Debug mode?
      def debug?
        ENV['ROLL_DEBUG']
      end

      # Warn mode?
      def warn?
        ENV['ROLL_WARN'] or $VERBOSE
      end

#      #
#      def metadir(location)
#        Dir.glob(File.join(location, '{meta,.meta}'))
#      end

#      # Load and parse version stamp file.
#      def load_version(location)
#        dir = Dir.glob(File.join(location, '{meta,.meta}'))
#        m = {}
#        m[:name]    = read_metadata_entry(dir, 'name') || read_metadata_entry(dir, 'package')
#        m[:version] = read_metadata_entry(dir, 'version')
#        m[:status]  = read_metadata_entry(dir, 'status')
#        m[:date]    = read_metadata_entry(dir, 'date') || read_metadata_entry(dir, 'release')
#        return m
#        #patt = File.join(location,'VERSION')
#        #file = Dir.glob(patt, File::FNM_CASEFOLD).first
#        #if file
#        #  parse_version_stamp(File.read(file))
#        #else
#        #  {}
#        #end
#      end

#      #
#      def read_metadata_entry(dir, name)
#        file = File.join(dir,name)
#        if File.file?(file)
#          File.read(file).strip
#        else
#          nil
#        end
#      end

#      # Wish there was a way to do this without using a
#      # configuration file.
#      def load_loadpath(location)
#        file = File.join(location, 'meta', 'loadpath')
#        if File.file?(file)
#          paths = File.read(file).gsub(/\n\s*\n/m,"")
#          paths = paths.split(/\s*\n/)
#        else
#          paths = ['lib']
#        end
#      end

      # Parse version stamp into it's various parts.
      #def parse_version_stamp(text)
      #  #info, *libpath = *data.split(/\s*\n\s*/)
      #  name, version, status, date = *text.split(/\s+/)
      #  version = Version.new(version)
      #  date    = Time.mktime(*date.scan(/[0-9]+/))
      #  #default = default || "../#{name}"
      #  return {:name => name, :version => version, :status => status, :date => date}
      #end

      # Get an instance of a library by package name. Libraries are singleton, so once loaded
      # the same object is always returned.
      def instance(package, constraint=nil)
        package = package.to_s

        #raise "no library -- #{package}" unless ledger.include?(package)
        return nil unless ledger.include?(package)

        library = ledger[package]

        if Library===library
          if constraint
            raise VersionConflict, "previously selected version -- #{ledger[package].version}"
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
            raise VersionError, "no library version -- #{package} #{constraint}"
          end

          #ledger[package] = version
          version.activate
        end
      end

      # A shortcut for #instance.
      alias_method :[], :instance

      # Same as #instance but will raise and error if the library is
      # not found. This can also take a block to yield on the library.
      def open(package, constraint=nil, &yld)
        lib = instance(package, constraint)
        unless lib
          raise LoadError, "no library -- #{package}"
        end
        yield(lib) if yld
        lib
      end

      # Dynamic link extension.
      #
      def dlext
        @dlext ||= '.' + ::Config::CONFIG['DLEXT']
      end

      # Standard load path. This is where all active libs
      # place there loadable locations.
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

      #alias_method :require_without_roll, :require
      #public :require_without_roll

      #alias_method :load_without_roll, :load
      #public :load_without_roll

      # Roll requires a modification to #require and #load.
      # So that it is not neccessary to make the library() call
      # if you just want the use latest version.
      #
      # [FIXME] This doesn't work for autoload. This is really
      # a bug in Ruby b/c autoload is not using #require.
      #
      def require(file)
        begin
          return Kernel.require(file)
        rescue LoadError => load_error
        end

        fname = "#{file}.rb" if File.extname(file) == ''

        lib = nil
        if @lookup.find{ |path, lib| File.file?(File.join(path, file)) }
          return lib.require(file)
        end

        # NOTE: We could use #collect w/ if instead of #find and see if there
        # is any path conflicts in packages without the same names.

        # try current library
        if lib = load_stack.last
          if lib.require_find(file)
            return lib.require(file)
          end
        end

        raise load_error
      end

      # Load
      #
      def load(file, wrap=false)
        begin
          return Kernel.load(file, wrap)
        rescue LoadError => load_error
        end

        fname = "#{file}.rb" if File.extname(file) == ''

        lib = nil
        if @lookup.find{ |path, lib| File.file?(File.join(path, file)) }
          return lib.load(file, wrap)
        end

        # try current library
        if lib = load_stack.last
          if lib.load_find(file)
            return lib.load(file, wrap)
          end
        end

        raise load_error
      end

      # Use acquire to use Roll-style loading. This first
      # looks for a specific library via ':'. If ':' is 
      # not present it then tries the current library.
      # Failing that it fallsback to Ruby itself.
      #
      #   acquire('facets:string/margin')
      #
      # To "load" the library, rather than "require":
      #
      #   acquire('facets:string/margin', :load=>true)
      #
      def acquire(file, opts={})
        if file.index(':') # a specific library
          name, file = file.split(':')
          lib = Library.open(name)
        else # try the current library
          cur = load_stack.last
          if cur && cur.load_find(file)
            lib = cur
          elsif !file.index('/') # is this a package name?
            if cur = Library.instance(file)
              lib  = cur
              file = lib.default # default file to load
            end
          end
        end
        if opts[:load]
          lib ? lib.load(file) : Kernel.load(file)
        else
          lib ? lib.require(file) : Kernel.require(file)
        end
      end

    end #module Management

    # VersionError is raised when a requested version cannot be found.
    class VersionError < ::RangeError  # :nodoc:
    end

    # VersionConflict is raised when selecting another version
    # of a library when a previous version has already been selected.
    class VersionConflict < ::LoadError  # :nodoc:
    end

  end #class Library

end #module Roll

