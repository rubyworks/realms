module Realms
  class Library
    # Manager class tracks available libraries by library name. It is essentially
    # a hash, but with a special way of storing libraries to track versions. Each
    # have key is the name of a library, as a String, and each value is either
    # a Library object, if that particular version is active, or an Array of
    # available versions of the library if inactive.
    #
    # TODO: Use a second variable to track active libraries ?
    #
    class Manager
      include Enumerable

      #
      # Holds a copy of the original $LOAD_PATH.
      #
      LOAD_PATH = $LOAD_PATH.dup

      #
      # Initialize Manager instance.
      #
      def initialize
        @ledger = {} #Hash.new(){ |h,k| h[k] = [] }
        #@active = {}
      end

      #
      # Add library to the ledger given a library location or a Library object.
      #
      # @todo: Name of this method sucks, change to what?
      #
      # @param [String,Library]
      #   The directory path to a ruby library or an instance of Library.
      #
      # @return [Library] Added library object.
      #
      def add(library)
        library = Library.new(library) unless Library === library

        #raise TypeError unless Library === library
        #begin
          entry = (@ledger[library.name] ||= [])

          case entry
          #when NilClass
          #  raise "serious shit! nil entry in ledger table!"
          when Array
            entry << library unless entry.include?(library)
          else
            # Library is already active so compare and make sure they are the
            # same, otherwise warn. (Should this ever raise an error?)
            if entry != library  # TODO: Is this the right equals comparison?
              warn "Added library has already been activated."
            end
          end
        #rescue Exception => error
        #  warn error.message if ENV['debug']
        #end

        library
      end

      #
      # Alias for #add method, but returns the ledger instead of the library.
      #
      def <<(library)
        add(library)
        self
      end

      #
      # Get library or library version set by name.
      #
      # @param [String] name
      #   Name of library.
      #
      # @return [Library,Array] Library or version set of libraries.
      #
      def [](name)
        @ledger[name.to_s] || []
      end

      #
      # Set ledger entry.
      #
      # @param [String] Name of library.
      #
      # @raise [TypeError] If library is not a Library object.
      #
      def []=(name, library)
        raise TypeError unless Library === library

        @ledger[name.to_s] = library
      end

      #
      # Get the most current library by name. This does not activate!
      #
      def current(name)
        Array(@ledger[name.to_s]).max
      end

      #
      # Replace current ledger with table from another.
      #
      # @param [Manager,Hash] other
      #   Another Manager instance or a ledger hash.
      #
      def replace(other)
        case other
        when Manager
          @ledger.replace(other.ledger)
        when Hash
          initialize  # reinitialize
          other.each do |name, value|
            @ledger[name.to_s] = (
              case value
              when Library then value
              when Hash    then Library.new(value['location'], value)
              when Array
                value.map do |val|
                  case val
                  when Library then val
                  when Hash    then Library.new(val['location'], val)
                  else raise TypeError
                  end
                end
              else raise TypeError
              end
            )
          end
        else
          raise TypeError
        end
      end

      #
      # Iterate over each ledger entry.
      #
      def each(&block)
        @ledger.each(&block)
      end

      #
      # Get a copy of the underlying table.
      #
      def to_h
        @ledger.dup
      end

      #
      # Size of the ledger is the number of libraries available.
      #
      # @return [Fixnum] Size of the ledger.
      #
      def size
        @ledger.size
      end

      # TODO: Seems like Manager#key?, #keys and #values should have better names.

      #
      # Checks ledger for presents of library by name.
      #
      # @return [Boolean]
      #
      def key?(name)
        @ledger.key?(name.to_s)
      end

      #
      # Get a list of names of all libraries in the ledger.
      #
      # @return [Array<String>] list of library names
      #
      def keys
        @ledger.keys
      end

      #
      alias :names :keys

      #
      # Get a list of libraries and library version sets in the ledger.
      #
      # @return [Array<Library,Array>] 
      #   List of libraries and library version sets.
      #
      def values
        @ledger.values
      end

      #
      # Inspection string.
      #
      # @return [String] Inspection string.
      #
      def inspect
        @ledger.inspect
      end

      #
      # Limit versions of a library to the given constraint.
      # Unlike `#activate` this does not reduce the possible versions
      # to a single library, but only reduces the number of possibilites.
      #
      # @param [String] name
      #   Name of library.
      #
      # @param [String] constraint
      #   Valid version constraint.
      #
      # @return [Array] List of conforming versions.
      #
      def constrain(name, constraint)
        name = name.to_s

        libraries = self[name]

        case libraries
        when Library
          if libraries.version.satisfy?(constraint)
            vers = [libraries]
          else
            vers = []
          end
        else #Array
          vers = libraries.select do |library|
            library.version.satisfy?(constraint)
          end
        end

        @ledger[name] = vers  #self[name] = vers
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
        activate(name, constraint) if key?(name)
      end

      #
      # Activate a library, retrieving a Library instance by name, or name
      # and version, and ensuring only that instance will be returned for
      # all subsequent requests. Libraries are singleton, so once activated
      # the same object is always returned.
      #
      # This method will raise a LoadError if the name is not found.
      #
      # Note that activating all runtime requirements of a library being
      # activated was considered, but decided against. There's no reason
      # to activate a library until it is actually needed. However this is
      # not so when testing, or verifying available requirements, so other
      # methods are provided such as `#activate_requirements`.
      #
      # @param [String] name
      #   Name of library.
      #
      # @param [String] constraint
      #   Valid version constraint.
      #
      # @return [Library]
      #   The activated Library object.
      #
      # @todo Need more specific errors?
      #
      def activate(name, constraint=nil) #:yield:
        raise LoadError, "no such library -- #{name}" unless key?(name)

        library = self[name]

        if Library === library
          if constraint
            unless library.version.satisfy?(constraint)
              #raise VersionConflict, library ?
              raise Version::Exception, "version conflict between #{library} and #{constraint}"
            end
          end
        else # library is an array of versions
          if constraint
            #verscon = Version::Constraint.parse(constraint)
            #library = library.select{ |lib| verscon.compare(lib.version) }.max
            library = constrain(name, constraint).max
          else
            library = library.max
          end
          unless library
            raise Version::Exception, "no library version -- #{name} #{constraint}"
          end
          self[name] = library #constrain(library)
        end

        yield(library) if block_given?

        library
      end

      #
      # Load file path. This is just like #require except that previously
      # loaded files will be reloaded and standard extensions will not be
      # automatically appended.
      #
      # @param pathname [String]
      #   Pathname of feature relative to library's loadpath.
      #
      # @return [true,false] If feature was successfully loaded.
      #
      def load(pathname, options={})
        options = {:wrap => options} unless Hash === options
        options = options.rekey

        from, path = File.split_root(pathname)

        library = instance(from)

        if library
          success = library.load(pathname, options)
        else
          stash_path = $LOAD_PATH
          #$LOAD_STACK << self
          $LOAD_PATH.replace(LOAD_PATH)
          begin
            success = load_without_realms(pathname, options[:wrap])
          ensure
            $LOAD_PATH.replace(stash_path)
            #$LOAD_STACK.pop
          end
        end

        success
      end

      # TODO: There is one issue with this design, users expect -I paths
      #       to be checked first.

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
        options = options.rekey

        from, path = File.split_root(pathname)

        library = instance(from)

        if library
          success = library.require(pathname, options)
        else
          stash_path = $LOAD_PATH
          #$LOAD_STACK << self
          $LOAD_PATH.replace(LOAD_PATH)
          begin
            success = require_without_realms(pathname)
          ensure
            $LOAD_PATH.replace(stash_path)
            #$LOAD_STACK.pop
          end
        end

        success
      end

      #
      # Require from current library.
      #
      # @param pathname [String]
      #   Pathname of feature relative to current library's load path.
      #
      # @return [true, false] If feature is newly required.
      #
      # @todo better name for `#require_local`?
      #
      def require_local(pathname, options={})
        library = $LOAD_STACK.last

        if library
          success = library.require(pathname, options)
          #load_path = $LOAD_PATH
          #$LOAD_PATH.replace(library.load_path)
          #begin
          #  success = require_without_realms(pathname)
          #rescue
          #  from, subpath = File.root_split(pathname)
          #  success = require_without_realms(subpath)
          #ensure
          #  $LOAD_PATH.replace(load_path)
          #end
        else
          stash_path = $LOAD_PATH
          #$LOAD_STACK << self
          $LOAD_PATH.replace(LOAD_PATH)
          begin
            success = require_without_realms(pathname)
          ensure
            $LOAD_PATH.replace(stash_path)
            #$LOAD_STACK.pop
          end       
        end

        success
      end

      #
      # Require from current library.
      #
      # @param pathname [String]
      #   Pathname of feature relative to current library's loadpath.
      #
      # @return [true, false] If feature is newly required.
      #
      def acquire(scope, pathname, options={})
        if path = find(pathname)
          unless $LOADED_SCOPE_FEATURES[scope].include?(path)
            $LOADED_SCOPE_FEATURES[scope] << path
            scope.module_eval(File.read(path), path)
          end
        else
          raise LoadError, "no such file -- #{pathname}"
        end
      end

      #
      # Find first matching file among libraies. If not found there, try the general $LOAD_PATH.
      # This search method coorepsonds to the way in which #require and #load lookup files.
      #
      # @return [String] Absolute file path.
      #
      def find(pathname, options={})
        options = options.rekey

        from, path = File.split_root(pathname)

        if absolute_path = Utils.absolute_path?(pathname)
          return absolute_path
        end

        # TODO: Should `-I` locations be searched first? What about ENV['RUBYLIB'] locations?

        library = current(from)

        if library
          file = library.find(pathname, options)
        else
          # TODO: Is searching all of $LOAD_PATH too much?
          file = Utils.find_path($LOAD_PATH, pathname, options)
        end

        file
      end

      #
      # Search for all matching library files that match the given pattern.
      # This could be of useful for plugin loader.
      #
      # @param [Hash] match
      #   File glob pattern to match against.
      #
      # @param [Hash] options
      #   Glob matching options.
      #
      # @option options [Boolean] :all
      #   Search all versions, not just the the most recent version of a given library.
      #   Library versions are search in order from latest version to oldest version.
      #
      # @return [Array] Matching file paths.
      #
      # @todo Should search support implicit suffixes?
      #
      # @todo Should it search $LOAD_PATH as well?
      #
      def search(match, options={})
        all = options[:all]

        matches = []

        each do |name, libs|
          case libs
          when Array
            libs = [libs.max] unless all
          else
            libs = [libs]
          end

          libs.sort.each do |lib|
            matches.concat(lib.search(match))
          end
        end

        matches.uniq
      end

=begin
    #
    # Brute force variation of `#find` looks through all libraries for a 
    # matching features.
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
    # @return [Feature] Matching feature.
    #
    def find_any(path, options={})
      #options = options.merge(:main=>true)

      # TODO: Perhaps the selected and unselected should be kept in separate lists?
      unselected, selected = *partition{ |name, libs| Array === libs }

      # broad search of pre-selected libraries
      selected.each do |(name, lib)|
        if path = lib.find(path, options)
          return path
        end
      end

      # finally a broad search on unselected libraries
      unselected.each do |(name, libs)|
        libs = libs.sort
        libs = [libs.first] if latest
        libs.each do |lib|
          if path = lib.find(path, options)
            return path
          end
        end
      end

      nil
    end

    #
    # Brute force search looks through all libraries for matching features.
    # This is the same as #find, but returns a list of matches rather
    # then the first matching feature found.
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
    def search_any(path, options={})
      options = options.merge(:main=>true)

      latest = options[:latest]

      matches = []

      # TODO: Perhaps the selected and unselected should be kept in separate lists?
      unselected, selected = *partition{ |name, libs| Array === libs }

      # broad search of pre-selected libraries
      selected.each do |(name, lib)|
        if path = lib.find(path, options)
          matches << path
        end
      end

      # finally a broad search on unselected libraries
      unselected.each do |(name, libs)|
        libs = [libs.sort.first] if latest
        libs.each do |lib|
          ftr = lib.find(path, options)
          matches << ftr if ftr
        end
      end

      matches.uniq
    end

=end

      #
      # Go thru each library and collect bin paths.
      #
      # TODO: Better name than #PATH()?
      #
      def PATH()
        path = []
        list.each do |name|
          lib = current(name)
          path << lib.bindir if lib.bindir?
        end
        path.join(Utils.windows_platform? ? ';' : ':')
      end

      #
      # Lookup libraries that have a depenedency on the given library name
      # and version constraint.
      #
      # @todo Does not yet handle version constraint.
      # @todo Sucky name ?
      #
      # @return [Array<Library>] 
      #
      def depend_upon(match_name) #, constraint)
        list = []
        each do |name, libs|
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
      # Load up the ledger with a given set of paths.
      #
      # @param [Array] paths
      #
      # @option paths [Boolean] :expound
      #   Expound on path entires. See {#expound_paths}.
      #
      # @return [Manager] The primed ledger.
      #
      def loadup(*paths)
        options = Hash === paths.last ? paths.pop : {}

        @ledger = {} #Hash.new(){ |h,k| h[k] = [] }

        paths = expound_paths(*paths) if options[:expound]

        paths.each do |path|
          begin
            add(path) if library_path?(path)
          rescue => err
            $stderr.puts err.message if Utils.monitor?
          end
        end

        # We can not do this b/c it prevents gems from working
        # when a file has the same name as something in the
        # ruby lib or site locations. For example, if we intsll
        # the test-unit gem and require `test/unit`. Of course,
        # it Ruby ever adopted the "Realms Way" then this could
        # be restored.
        #add_library(RubyLibrary.new)

        self
      end

      #
      # Like #loadup but empties the ledger table first.
      #
      # @param [Array] paths
      #
      # @option paths [Boolean] :expound
      #   Expound on path entires. See {#expound_paths}.
      #
      # @return [Manager] The primed ledger.
      #
      def prime(*paths)
        @ledger = Hash.new(){ |h,k| h[k] = [] }
        loadup(*paths)
      end

=begin
    #
    # Reduce the ledger to only those libraries the given library requires.
    #
    # @param [String] name
    #   The name of the primary library.
    #
    # @param [String] constraint
    #   The version constraint string.
    #
    # @return [Manager] The ledger.
    #
    def isolate(name, constraint=nil)
      library = activate(name, constraint)

      # TODO: shouldn't this be done in #activate ?
      acivate_requirements(library)

      unused = []
      each do |name, libs|
        ununsed << name if Array === libs
      end
      unused.each{ |name| @ledger.delete(name) }

      self
    end
=end

      #
      # Add a library given it's path and reduce the ledger to just those libraries
      # the given library requires.
      #
      # @param [String] name
      #   The name of the primary library.
      #
      # @param [String] constraint
      #   The version constraint string.
      #
      # @return [Manager] The ledger.
      #
      def isolate_project(root)
        # add location to ledger
        library = add(root)

        # make this library the active one
        #$LEDGER[library.name] = library

        resolver = ::Version::Resolver.new

        $LEDGER.each do |name, libs|
          Array(libs).reverse_each do |lib|
            reqs = {}
            lib.requirements.each do |r|
              next if r['optional'] || (r['groups'] || []).include?('optional')
              reqs[r['name']] = r['version']   #|| '>= 0'
            end
            resolver.add(name, lib.version, reqs)
          end
        end

        solution = resolver.resolve(library.name, library.version)

        if solution
          # translate solution into an isolated ledger
          little_ledger = {}
          solution.each do |name, version|
            little_ledger[name] = constrain(name, "= #{version}").max
          end
          $LEDGER.replace(little_ledger)
        else
          warn "Unresolved Requirements!"
          resolver.unresolved.each do |from, reqs|
            $stderr.puts "%s %s:" % from
            reqs.each do |req|
              $stderr.puts "  %s %s" % req
            end
          end
          #raise "unresolved requirements"
        end

        return library
      end

      #
      #
      #
      #def to_json
      #  #JSON.dump(to_h)
      #  JSON.pretty_generate(to_h)
      #end

      #
      #
      #
      def to_h
        h = {}
        @ledger.each do |name, libs|
          h[name] = (
            case libs
            when Array
              libs.map{ |lib| lib.to_h }
            else
              libs.to_h
            end
          )
        end
        h
      end

    protected

      #
      # Protected access to underlying ledger table.
      #
      def ledger
        @ledger
      end

    private

      #
      # For flexible priming, this method is used to recursively
      # lookup library locations.
      #
      # If a given path is a file, it will considered a lookup *roll*,
      # such that each line entry in the file is considered another
      # path to be expounded upon.
      #
      # If a given path is a directory, it will be returned if it
      # is a valid Ruby library location.
      #
      # If it is a directory each of its subdirectories will be checked
      # to see if it is a valid Ruby library location, and returned if so.
      #
      # However, if the directory contains a subdirectory called `gems`,
      # that directory will be serache instead. This is done to support
      # RubyGems locations via the `$HOME_PATH`.
      #
      # If, on the other hand, a given path is a file glob pattern,
      # the pattern will be expanded and those paths will expounded
      # upon in turn.
      #
      # @param [Array<String>] entries
      #   File system paths to use to build list of library locations.
      #
      # @return [Array<String>] List of verified library locations.
      #
      def expound_paths(*entries)
        paths = []

        entries.each do |entry|
          entry = entry.strip

          next if entry.empty?
          next if entry.start_with?('#')

          if File.directory?(entry)
            if library_path?(entry)
              paths << entry
            else
              if File.directory?(File.join(entry, 'gems'))
                subpaths = Dir.glob(File.join(entry, 'gems/*/'))
              else
                subpaths = Dir.glob(File.join(entry, '*/'))
              end
              subpaths.each do |subpath|
                paths << subpath if library_path?(subpath)
              end
            end
          elsif File.file?(entry)
            paths.concat(expound_paths(*File.readlines(entry)))
          else
            glob_paths = Dir.glob(entry)
            if glob_paths.first != entry
              paths.concat(expound_paths(*glob_paths))
            end
          end
        end

        paths
      end

      #
      # Is a directory a Ruby library?
      #
      # @todo Support gem home location.
      #
      def library_path?(path)
        #dotindex(path) || (ENV['RUBYLIBS_GEMSPEC'] && gemspec(path))
        if ENV['RUBY_LIBRARY_NO_GEMS']
          dotindex(path)
        else
          dotindex(path) || gemspec(path)
        end
      end

      # TODO: First recursively constrain the ledger, then activate. That way
      # any missing libraries will cause an error. (hmmm... actually that's
      # an imperfect way to resolve version dependencies). Ultimately we probably
      # need a separate module to handle this.

      #
      # Activate library requirements.
      #
      # @todo: checklist is used to prevent possible infinite recursion, but
      #   it might be better to put a flag in Library instead.
      #
      def acivate_requirements(library, development=false, checklist={})
        reqs = development ? library.requirements : library.runtime_requirements

        checklist[library] = true

        reqs.each do |req|
          name = req['name']
          vers = req['version']

          library = activate(name, vers)

          activate_requirements(library, development, checklist) unless checklist[library]
        end

        self
      end

      #
      # Constrain library requirements.
      #
      def constrain_requirements(library, development=false, checklist={})
        reqs = development ? library.requirements : library.runtime_requirements

        checklist[library] = true

        reqs.each do |req|
          name = req['name']
          vers = req['version']

          libr = constrain(name, vers)

          constrain_requirements(library, development, checklist) unless checklist[libr]
        end

        return self
      end

      #
      # If the directory has a `.index` file return it, otherwise +nil+.
      #
      def dotindex(path)
        file = File.join(path, '.index')
        File.file?(file) ? file : false
      end

      alias :dotindex? :dotindex

      # TODO: Would it be faster to determine gem?(path) if we just compared it to $GEM_PATH?
      # If so, it might be faster, we could find the gemspec file from there. Right now this
      # code is too redundant, and thus slower than need be.

      #
      # Does a path have a `.gemspec` file? This is fallback measure
      # if a `.index` file is not found.
      #
      def gemspec(path)
        installed_gemspec(path) || local_gemspec(path)
      end

      alias :gemspec? :gemspec

      #
      # Does a path have a `.gemspec` file?
      #
      def local_gemspec(path)
        glob = File.join(path, '{,*}.gemspec')
        Dir[glob].first
      end

      #
      # Determine if a path belongs to an installed gem. If so, it returns the
      # path to the gemspec, otherwise +false+.
      #
      # @return [String, NilClass] Path to gemspec, or nil.
      #
      def installed_gemspec(path)
        #return true if Dir[File.join(path, '*.gemspec')].first
        pkgname = ::File.basename(path)
        gemsdir = ::File.dirname(path)
        specdir = ::File.join(File.dirname(gemsdir), 'specifications')
        gemspec = ::File.join(specdir, "#{pkgname}.gemspec")
        ::File.exist?(gemspec) ? gemspec : nil
      end

    end

  end

end
