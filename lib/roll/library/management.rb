require 'roll/environment'

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

      # Setup library system.
      #
      def setup
        @environment = Environment.new
        @ledger = {}
        @lookup = []

        # Add Ruby's core and standard libraries to the ledger.
        #@ledger['ruby'] = Library.new(
        #  Library.rubylibdir,
        #  :name=>'ruby',
        #  :version=>RUBY_VERSION,
        #  :libpath=>Library.ruby_path
        #)

        load_projects
      end

      #
      #def current_ledger
      #  environment.name #@user_ledger_file
      #end

      #
      attr :environment

      #
      attr :ledger

      #
      attr :lookup

      # Return a list of library names. (Add version?)
      def list
        ledger.keys
      end

      # Load projects into ledger.
      def load_projects
        environment.each do |location|
          begin
            lib = Library.new(location)
            name = lib.name.downcase
            ledger[name] ||= []
            ledger[name] << lib
            loadpath = lib.loadpath #|| ['lib']
            loadpath.each do |path|
              @lookup << [File.join(location, path), lib]
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

      # If monitor mode is on, this is used to store backtraces
      # for each load/require.
      def load_monitor
        @load_monitor ||= {}
      end

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
            compare = Version.constraint_lambda(constraint)
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
      # on top of the stack is the one currently loading.
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
        load_monitor[file] = caller if $LOAD_MONITOR

        begin
          return Kernel.require(file)
        rescue LoadError => load_error
        end

        file = "#{file}.rb" if File.extname(file) == ''

        lib = nil
        found = @lookup.find do |path, lib|
          File.file?(File.join(path, file))
        end
        if found
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

        raise clean_backtrace(load_error)
      end

      # Load
      #
      def load(file, wrap=false)
        load_monitor[file] = caller if $LOAD_MONITOR

        begin
          return Kernel.load(file, wrap)
        rescue LoadError => load_error
        end

        file = "#{file}.rb" if File.extname(file) == ''

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

        raise clean_backtrace(load_error)
      end

      #
      def clean_backtrace(error)
        if $DEBUG
          error
        else
          bt = error.backtrace
          bt = bt.reject{ |e| /roll/ =~ e }
          error.set_backtrace(bt)
          error
        end
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

