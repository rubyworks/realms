module Realms
  class Library
    # Utils module provides general shared functions needed throughout the system,
    # but primarily at the toplevel to be used in bootstrapping the system.
    #
    module Utils
      extend self

      #
      # Possible suffixes for feature files, that #require will try automatically.
      #
      SUFFIXES = ['.rb', '.rbw', '.so', '.bundle', '.dll', '.sl', '.jar'] #, '']

      #
      # The opposite of SUFFIXES. Using this helps DRY-up the find_feature code.
      #
      SUFFIXES_NOT = ['']

      #
      # Lock the load manager ledger, by saving it to the temporary lock file.
      #
      # @todo Should we update the ledger first?
      #
      def lock
        output = lock_file

        dir = File.dirname(output)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)

        File.open(output, 'w+') do |f|
          #f << JSON.fast_generate($LOAD_MANAGER.to_h)
          f << JSON.pretty_generate($LOAD_MANAGER.to_h)
          #f << Marshal.dump($LOAD_MANAGER)
        end
      end

      #
      # Remove lock file and reset the load manager's ledger.
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
      # Reset the load manager.
      #
      def reset!
        #$LOAD_MANAGER = LoadManager.new
        #$LOAD_STACK = []
        $LOAD_CACHE = {}

        if File.exist?(lock_file) && ! live?
          ledger = JSON.load(File.new(lock_file))
          #ledger = Marshal.load(File.new(lock_file))
          case ledger
          when Manager
            $LOAD_MANAGER = ledger
            return $LOAD_MANAGER
          when Hash
            $LOAD_MANAGER.replace(ledger)
            return $LOAD_MANAGER
          else
            warn "Bad cached ledger at #{lock_file}"
            #$LOAD_MANAGER = Manager.new
          end
        else
          #$LOAD_MANAGER = Manager.new
        end

        $LOAD_MANAGER.prime(*lookup_paths, :expound=>true)

        #if development?
          # find project root
          # if root
          #   $LOAD_MANAGER.isolate_project(root)
          # end
        #end
      end

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

      #
      # TODO: Not sure RUBYLIB environment should be included in user_path.
      #

      #
      # Lookup a path in locations that were added to $LOAD_PATH manually.
      # These include those added via `-I` command line option, the `RUBYLIB`
      # environment variable and those add to $LOAD_PATH via code.
      #
      # This is a really throwback to the old load system. But it is necessary as
      # long as the old system is used, to ensure expected behavior.
      #
      # @return [String]
      def find_userpath(path, options)
        find_path(user_path, path, options)
      end

      #
      # Find a path in the given load paths, taking into account load options.
      #
      # @return [String]
      #
      def find_path(loadpath, pathname, options)
        return nil if loadpath.empty?

        suffix = options[:suffix] || options[:suffix].nil?
        #suffix = true if options[:require]                             # TODO: Is this always true?
        suffix = false if SUFFIXES.include?(::File.extname(pathname))   # TODO: Why not just add '' to SUFFIXES?

        suffixes = suffix ? SUFFIXES : SUFFIXES_NOT

        loadpath.each do |lpath|
          suffixes.each do |ext|
            f = ::File.join(lpath, pathname + ext)
            return f if ::File.file?(f)
          end
        end

        return nil
      end

      #
      # Lookup a path in locations that were added to $LOAD_PATH manually.
      # These include those added via `-I` command line option, the `RUBYLIB`
      # environment variable and those add to $LOAD_PATH via code.
      #
      # @return [Array<String>]
      #
      def user_path
        load_path = $LOAD_PATH - ruby_library_locations
        load_path = load_path.reject{ |p| gem_paths.any?{ |g| p.start_with?(g) } }
      end

      #
      # Ruby library locations as given in RbConfig.
      #
      # @return [Array<String>]
      #
      def ruby_library_locations
        @_ruby_library_locations ||= (
          RbConfig::CONFIG.values_at(
            'rubylibdir',
            'archdir',
            'sitedir',
            'sitelibdir',
            'sitearchdir',
            'vendordir',
            'vendorlibdir',
            'vendorarchdir'
          )
        )
      end

      #
      # List of gem paths taken from the environment variable `GEM_PATH`, or failing
      # that `GEM_HOME`.
      #
      # @todo Perhaps these should be taken directly from Gem module instead?
      #
      # @return [Array<String>]
      #
      def gem_paths
        @_gem_paths ||= (ENV['GEM_PATH'] || ENV['GEM_HOME']).split(/[:;]/)
      end

      #
      # Is the current platform a Windows-based OS?
      #
      # @todo This is one of those methods that probably can always
      #       use a little improvement.
      #
      def windows_platform?
        case RUBY_PLATFORM
        when /cygwin|mswin|mingw|bccwin|wince|emx/
          true
        else
          false
        end
      end

      #
      #
      #
      def absolute_path?(path)
        case path[0,1]
        when '/', '~', '.'
          File.expand_path(path)
        else
          false
        end
      end

      #
      # State of monitoring setting. This is used for debugging.
      #
      def monitor?
        ENV['monitor'] || ($MONITOR ||= false)
      end

    end

  end
end
