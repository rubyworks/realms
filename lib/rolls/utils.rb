module Rolls

  module Utils
    extend self

    SUFFIXES = Library::SUFFIXES
    SUFFIXES_NOT = Library::SUFFIXES_NOT

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

  end

end
