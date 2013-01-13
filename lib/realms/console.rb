class Realms::Library

  # This module simply extends the Library class, giving it certain
  # convenience methods for interacting with the current Ledger.
  #
  # TODO: Change name of module?
  #
  module Console

    require 'tmpdir'

    #
    # Access to library ledger.
    #
    # @return [Array] The `$LEDGER` array.
    #
    def ledger
      $LEDGER
    end

    #
    # Library names from ledger.
    #
    # @return [Array] The keys from `$LEDGER` array.
    #
    def names
      $LEDGER.keys
    end

    alias_method :list, :names

    #
    # A shortcut for #instance.
    #
    # @return [Library,NilClass] The activated Library instance, or `nil` if not found.
    #
    def [](name, constraint=nil)
      $LEDGER.activate(name, constraint) if $LEDGER.key?(name)
    end

    #
    # Get an instance of a library by name, or name and version.
    # Libraries are singleton, so once loaded the same object is
    # always returned.
    #
    # @todo This method might be deprecated.
    #
    # @return [Library,NilClass] The activated Library instance, or `nil` if not found.
    #
    def instance(name, constraint=nil)
      $LEDGER.activate(name, constraint) if $LEDGER.key?(name)
    end

    #
    # Activate a library. Same as #instance but will raise and error if the
    # library is not found. This can also take a block to yield on the library.
    #
    # @param [String] name
    #   Name of library.
    #
    # @param [String] constraint
    #   Valid version constraint.
    #
    # @raise [LoadError]
    #   If library not found.
    #
    # @return [Library]
    #   The activated Library object.
    #
    def activate(name, constraint=nil, &block) #:yield:
      $LEDGER.activate(name, constraint, &block)
    end

    #
    # Like `#new`, but adds library to library ledger.
    #
    # @todo Better name for this method?
    #
    # @return [Library] The new library.
    #
    def add(location)
      $LEDGER.add(location)
    end

    #
    # Find matching library features. This is the "mac daddy" method used by
    # the #require and #load methods to find the specified +path+ among
    # the various libraries and their load paths.
    #
    def find(path, options={})
      $LEDGER.find_feature(path, options)
    end

    #
    # Brute force variation of `#find` looks through all libraries for a 
    # matching features. This serves as the fallback method if `#find` comes
    # up empty.
    #
    # @param [String] path
    #   path name for which to search
    #
    # @param [Hash] options
    #   Search options.
    #
    # @option options [Boolean] :latest
    #   Search only the active or most current version of any library.
    #
    # @option options [Boolean] :suffix
    #   Automatically try standard extensions if pathname has none.
    #
    # @option options [Boolean] :legacy
    #   Do not match within library's +name+ directory, eg. `lib/foo/*`.
    #
    # @return [Feature,Array] Matching feature(s).
    #
    def find_any(path, options={})
      $LEDGER.find_any(path, options)
    end

    #
    # Brute force search looks through all libraries for matching features.
    # This is the same as #find_any, but returns a list of matches rather
    # then the first matching feature found.
    #
    # @param [String] glob
    #   Glob pattern for which to search.
    #
    # @param [Hash] options
    #   Search options.
    #
    # @option options [Boolean] :latest
    #   Search only the active or most current version of any library.
    #
    # @option options [Boolean] :suffix
    #   Automatically try standard extensions if pathname has none.
    #
    # @option options [Boolean] :legacy
    #   Do not match within library's +name+ directory, eg. `lib/foo/*`.
    #
    # @return [Feature,Array] Matching feature(s).
    #
    def search(glob, options={})
      $LEDGER.search(glob, options)
    end

=begin
    #
    # Search for all matching library files that match the given pattern.
    # This could be of useful for plugin loader.
    #
    # @param [Hash] options
    #   Glob matching options.
    #
    # @option options [Boolean] :latest
    #   Search only activated libraries or the most recent version
    #   of a given library.
    #
    # @return [Array] Matching file paths.
    #
    # @todo Should this return list of Feature objects instead of file paths?
    #
    def glob(match, options={})
      $LEDGER.glob(match, options)
    end
=end

    #
    # Access to global load stack.
    # When loading files, the current library doing the loading is pushed
    # on this stack, and then popped-off when it is finished.
    #
    # @return [Array] The `$LOAD_STACK` array.
    #
    def load_stack
      $LOAD_STACK
    end

    #
    # Require a feature from the library.
    #
    # @param [String] pathname
    #   The pathname of feature relative to library's loadpath.
    #
    # @param [Hash] options
    #
    # @return [true,false] If feature was newly required or successfully loaded.
    #
    def require(pathname, options={})
      $LEDGER.require(pathname, options)
    end

    #
    # Load file path. This is just like #require except that previously
    # loaded files will be reloaded and standard extensions will not be
    # automatically appended.
    #
    # @param pathname [String]
    #   pathname of feature relative to library's loadpath
    #
    # @return [true,false] if feature was successfully loaded
    #
    def load(pathname, options={}) #, &block)
      $LEDGER.load(pathname, options)
    end

    #
    # Like require but also with local lookup. It will first check to see
    # if the currently loading library has the path relative to its load paths.
    #
    #   acquire('core_ext/margin')
    #
    # To "load" the library, rather than "require" it, set the +:load+
    # option to true.
    #
    #   acquire('core_ext/string/margin', :load=>true)
    #
    # @param pathname [String]
    #   Pathname of feature relative to library's loadpath.
    #
    # @return [true, false] If feature was newly required.
    #
    def acquire(pathname, options={}) #, &block)
      $LEDGER.acquire(pathname, options)
    end

    #
    # Lookup libraries that have a depenedency on the given library name
    # and version.
    #
    # @todo Does not yet handle version constraint.
    # @todo Sucky name.
    #
    # @return [Array<Library>] 
    #
    def depends_upon(match_name) #, constraint)
      list = []
      $LEDGER.each do |name, libs|
        case libs
        when Library
          list << libs if libs.requirements.any?{ |r| match_name == r['name']  } 
        else
          libs.each do |lib|
            list << lib if lib.requirements.any?{ |r| match_name == r['name']  } 
          end
        end
      end
      list
    end

    #
    # Go thru each library and collect bin paths.
    #
    # @todo Should this be defined on Ledger?
    #
    def PATH()
      path = []
      list.each do |name|
        lib = $LEDGER.current(name)
        path << lib.bindir if lib.bindir?
      end
      path.join(Utils.windows_platform? ? ';' : ':')
    end

    #
    # Lock the ledger, by saving it to the temporary lock file.
    #
    # @todo Should we update the ledger first?
    #
    def lock
      output = lock_file

      dir = File.dirname(output)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)

      File.open(output, 'w+') do |f|
        #f << JSON.fast_generate($LEDGER.to_h)
        f << JSON.pretty_generate($LEDGER.to_h)
        #f << Marshal.dump($LEDGER)
      end
    end

    #
    # Remove lock file and reset ledger.
    #
    def unlock
      FileUtils.rm(lock_file) if File.exist?(lock_file)
      reset!
    end

    #
    # Synchronize the ledger to the current system state and save.
    # Also, returns the bin paths of all libraries.
    #
    # @return [Array<String>] List of bin paths.
    #
    def sync
      unlock if locked?
      lock
      PATH()
    end

    #
    # Library lock file.
    #
    # @return [String] Path to ledger lock file.
    # 
    def lock_file
      File.join(tmpdir, "#{ruby_version}.ledger")
    end

    #
    # Check is `RUBY_LIBRARY_LIVE` environment variable is set on.
    #
    # @return [Booelan] Using live mode?
    #
    def live?
      case ENV['RUBY_LIBRARY_LIVE'].to_s.downcase
      when 'on', 'true', 'yes', 'y'
        true
      else
        false
      end
    end

=begin
  #
  # Check is `RUBY_LIBRARY_DEVELOPMENT` environment variable is set on.
  #
  # @return [Booelan] Using development mode?
  #
  def development?
    case ENV['RUBY_LIBRARY_DEVELOPMENT'].to_s.downcase
    when 'on', 'true', 'yes', 'y'
      true
    else
      false
    end
  end
=end

    #
    # Is there a saved locked ledger?
    #
    def locked?
      File.exist?(lock_file)
    end

    #
    # Reset the Ledger.
    #
    def reset!
      #$LEDGER = Ledger.new
      #$LOAD_STACK = []
      $LOAD_CACHE = {}

      if File.exist?(lock_file) && ! live?
        ledger = JSON.load(File.new(lock_file))
        #ledger = Marshal.load(File.new(lock_file))
        case ledger
        when Ledger
          $LEDGER = ledger
          return $LEDGER
        when Hash
          $LEDGER.replace(ledger)
          return $LEDGER
        else
          warn "Bad cached ledger at #{lock_file}"
          #$LEDGER = Ledger.new
        end
      else
        #$LEDGER = Ledger.new
      end

      $LEDGER.prime(*lookup_paths, :expound=>true)

      #if development?
        # find project root
        # if root
        #   $LEDGER.isolate_project(root)
        # end
      #end
    end

    #
    # List of paths where the lookup of libraries should proceed.
    # This come from the `RUBY_LIBRARY` environment variable, if set.
    # Otherwise it fallback to `GEM_PATH` or `GEM_HOME`.
    #
    def lookup_paths
      if list = ENV['RUBY_LIBRARY']
        list.split(/[:;]/)
      #elsif File.exist?(path_file)
      #  File.readlines(path_file).map{ |x| x.strip }.reject{ |x| x.empty? || x =~ /^\s*\#/ }
      elsif ENV['GEM_PATH']
        ENV['GEM_PATH'].split(/[:;]/).map{ |dir| File.join(dir, 'gems', '*') }
      elsif ENV['GEM_HOME']
        ENV['GEM_HOME'].split(/[:;]/).map{ |dir| File.join(dir, 'gems', '*') }
      else
        warn "No Ruby libraries."
        []
      end
    end

  private

    #
    # Bootstap the system, which is to say hit `#reset!` and
    # load the Kernel overrides.
    #
    def bootstrap!
      reset!
      require_relative 'kernel'
    end

    #
    # A temporary directory in which the locked ledger can be stored.
    #
    def tmpdir
      File.join(Dir.tmpdir, 'ruby')
    end

    #
    # Get an identifier for the current Ruby. This is taken from the basename of
    # the `RUBY_ROOT` environment variable, if it exists, otherwise the `RUBY_VERSION`
    # constant is returned.
    #
    # @return [String] Ruby version indentifier.
    #
    def ruby_version
      if ruby = ENV['RUBY_ROOT']
        File.basename(ruby)
      else
        RUBY_VERSION
      end
    end

    #
    # Library list file.
    #
    #def path_file
    #  File.expand_path("~/.ruby/#{ruby_version}.path")
    #  #File.expand_path('~/.ruby-path')
    #end

  end

  extend Console

end
