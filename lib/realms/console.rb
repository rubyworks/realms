module Realms
  class Library

    # The ClassInterface module provides a convenience interface via the Library
    # metaclass, primarily giving it methods for interacting with the current
    # load manager.
    #
    module ClassInterface

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
      # Access to library load manager.
      #
      # @return [Manager] The global load manager. 
      #
      def load_manager
        $LOAD_MANAGER
      end

      #
      # Library names from manager.
      #
      # @return [Array] The keys from `$LOAD_MANAGER` array.
      #
      def names
        $LOAD_MANAGER.keys
      end

      alias_method :list, :names

      #
      # A shortcut for #instance.
      #
      # @return [Library,NilClass] The activated Library instance, or `nil` if not found.
      #
      def [](name, constraint=nil)
        $LOAD_MANAGER.activate(name, constraint) if $LOAD_MANAGER.key?(name)
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
        $LOAD_MANAGER.activate(name, constraint) if $LOAD_MANAGER.key?(name)
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
        $LOAD_MANAGER.activate(name, constraint, &block)
      end

      #
      # Like `#new`, but adds library to library manager.
      #
      # @todo Better name for this method?
      #
      # @return [Library] The new library.
      #
      def add(location)
        $LOAD_MANAGER.add(location)
      end

      #
      # Find matching library features. This is the "mac daddy" method used by
      # the #require and #load methods to find the specified +path+ among
      # the various libraries and their load paths.
      #
      def find(path, options={})
        $LOAD_MANAGER.find_feature(path, options)
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
        $LOAD_MANAGER.find_any(path, options)
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
        $LOAD_MANAGER.search(glob, options)
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
      $LOAD_MANAGER.glob(match, options)
    end
=end

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
        $LOAD_MANAGER.require(pathname, options)
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
        $LOAD_MANAGER.load(pathname, options)
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
        $LOAD_MANAGER.acquire(pathname, options)
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
      def depend_upon(match_name) #, constraint)
        $LOAD_MANAGER.depend_upon(match_name) #, constraint)
      end

      #
      # Go thru each library and collect bin paths.
      #
      # @todo Should this be defined on Manager?
      #
      def PATH()
        $LOAD_MANAGER.PATH()
      end

    end

    extend ClassInterface

  end
end
