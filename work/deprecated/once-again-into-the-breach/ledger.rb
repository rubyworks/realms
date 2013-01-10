module Rolls

  # Ledger class tracks available libraries by library name.
  # It is essentially a hash object, but with a special way
  # of storing library references in order to track versions.
  # Each key is the name of a library, as a String, and each
  # value is either a Library object, if a particular version
  # is active, or an Array of available versions of the library
  # if inactive.
  #
  class Ledger

    #
    # Access to library ledger.
    #
    # @return [Array] The `$LEDGER` array.
    #
    def self.ledger
      $LEDGER
    end

    #
    # Library names from ledger.
    #
    # @return [Array] The keys from `$LEDGER` array.
    #
    def self.names
      $LEDGER.keys
    end

    #
    # Library names from ledger.
    #
    # @return [Array] The keys from `$LEDGER` array.
    #
    def self.list
      $LEDGER.keys
    end

    #
    # Find matching library features. This is the "mac daddy" method used by
    # the #require and #load methods to find the specified +path+ among
    # the various libraries and their load paths.
    #
    def self.find(path, options={})
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
    def self.find_any(path, options={})
      $LEDGER.find_any(path, options)
    end

    #
    # Brute force search looks through all libraries for matching features.
    # This is the same as #find_any, but returns a list of matches rather
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
    def self.search(path, options={})
      $LEDGER.search(path, options)
    end

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
    def self.glob(match, options={})
      $LEDGER.glob(match, options)
    end

    #
    # @deprecated
    #
    def self.find_files(match, options={})
      glob(match, options)
    end

    #
    # Access to global load stack.
    #
    # @return [Array] The `$LOAD_STACK` array.
    #
    def self.load_stack
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
    def self.require(pathname, options={})
      #options_prior = ($LOAD_OPTIONS ||= {})
      #$LOAD_OPTIONS = options
      #$LOAD_OPTIONS[:legacy] = true if options_prior[:legacy]

      #begin
        if file = $LOAD_CACHE[pathname]
          if options[:load]
            return file.load
          else
            return false
          end
        end

        #unless $LOAD_OPTIONS[:legacy]

        if feature = find(pathname, options)
          #feature.library_activate
          $LOAD_CACHE[pathname] = feature
          return feature.acquire(options)
        end

        #end

        # fallback to Ruby's own load mechinisms
        if options[:load]
          __load__(pathname, options[:wrap])
        else
          __require__(pathname)
        end
      #ensure
      #  $LOAD_OPTIONS = options_prior
      #end
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
    def self.load(pathname, options={}) #, &block)
      #options.merge!(block.call) if block

      unless Hash === options
        options = {}
        options[:wrap] = options 
      end

      options[:load]   = true
      options[:suffix] = false
      options[:local]  = false

      require(pathname, options)

      #if file = $LOAD_CACHE[path]
      #  return file.load
      #end

      #if file = Library.find(path, options)
      #  #file.library_activate
      #  $LOAD_CACHE[path] = file
      #  return file.load(options) #acquire(options)
      #end

      ##if options[:load]
      #  __load__(path, options[:wrap])
      ##else
      ##  __require__(path)
      ##end
    end

    #
    # Roll-style loading. First it looks for a specific library via `:`.
    # If `:` is not present it then tries the current loading library.
    # Failing that it fallsback to Ruby itself.
    #
    #   require('facets:string/margin')
    #
    # To "load" the library, rather than "require" it, set the +:load+
    # option to true.
    #
    #   require('facets:string/margin', :load=>true)
    #
    # @param pathname [String]
    #   pathname of feature relative to library's loadpath
    #
    # @return [true, false] if feature was newly required
    #
    def self.acquire(pathname, options={}) #, &block)
      #options.merge!(block.call) if block
      options[:local] = true
      require(pathname, options)
    end

    #
    # Load up the ledger with a given set of paths.
    #
    def self.prime(*paths)
      $LEDGER.prime(*paths)
    end

    #
    # A ledger is enumerable, iterating over the internal table
    # of libraries.
    #
    include Enumerable

    #
    # State of monitoring setting. This is used for debugging.
    #
    def monitor?
      ENV['monitor'] || ($MONITOR ||= false)
    end

    #
    def initialize
      @table = Hash.new(){ |h,k| h[k] = [] }
    end

    #
    # Add a library to the ledger.
    #
    # @param [String,Library]
    #   A path to a ruby library or a Library object.
    #
    # @return [Library] Added library object.
    #
    def add(lib)
      case lib
      when Library
        add_library(lib)
      else
        add_location(lib)
      end
    end

    alias_method :<<, :add

    #
    # Add library to ledger given a location.
    #
    # @return [Library] Added library object.
    #
    def add_location(location)
      begin
        library = Library.new(location)

        entry = @table[library.name]

        if Array === entry
          entry << library unless entry.include?(library)
        else
          # todo: what to do here?
        end
      rescue Exception => error
        warn error.message if ENV['debug']
      end

      library
    end

    #
    # Add library to ledger given a Library object.
    #
    # @return [Library] Added library object.
    #
    def add_library(library)
      #begin
        raise TypeError unless Library === library

        entry = @table[library.name]

        if Array === entry
          entry << library unless entry.include?(library)
        end
      #rescue Exception => error
      #  warn error.message if ENV['debug']
      #end

      library
    end

    #
    # Get library or library version set by name.
    #
    # @param [String] name
    #   Name of library.
    #
    # @return [Library,Array] Library or lihbrary set referenced by name.
    #
    def [](name)
      @table[name.to_s]
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

      @table[name.to_s] = library
    end

    #
    #
    #
    def replace(table)
      initialize
      table.each do |name, value|
        @table[name.to_s] = value
      end
    end

    #
    # Iterate over each ledger entry.
    #
    def each(&block)
      @table.each(&block)
    end

    #
    # Size of the ledger is the number of libraries available.
    #
    # @return [Fixnum] Size of the ledger.
    #
    def size
      @table.size
    end

    #
    # Checks ledger for presents of library by name.
    #
    # @return [Boolean]
    #
    def key?(name)
      @table.key?(name.to_s)
    end

    #
    # Get a list of names of all libraries in the ledger.
    #
    # @return [Array<String>] list of library names
    #
    def keys
      @table.keys
    end

    #
    # Get a list of libraries and library version sets in the ledger.
    #
    # @return [Array<Library,Array>] 
    #   List of libraries and library version sets.
    #
    def values
      @table.values
    end

    #
    # Inspection string.
    #
    # @return [String] Inspection string.
    #
    def inspect
      @table.inspect
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
    def constrain(name, contraint)
      libraries = self[name]

      return nil unless Array === libraries

      vers = libraries.select do |library|
        library.version.satisfy?(constraint)
      end

      self[name] = vers
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
    # to activatea library until it is actually needed. However this is
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
    # @todo Should we also check $"? Eg. `return false if $".include?(path)`.
    #
    def activate(name, constraint=nil)
      raise LoadError, "no such library -- #{name}" unless key?(name)

      library = self[name]

      if Library === library
        if constraint
          unless library.version.satisfy?(constraint)
            raise Library::VersionConflict, library
          end
        end
      else # library is an array of versions
        if constraint
          verscon = Version::Constraint.parse(constraint)
          library = library.select{ |lib| verscon.compare(lib.version) }.max
        else
          library = library.max
        end
        unless library
          raise VersionError, "no library version -- #{name} #{constraint}"
        end

        self[name] = library #constrain(library)
      end

      library
    end

    #
    # Find matching library features. This is the "mac daddy" method used by
    # the #require and #load methods to find the specified +path+ among
    # the various libraries and their load paths.
    #
    def find_feature(path, options={})
      path   = path.to_s

      #suffix = options[:suffix]
      search = options[:search]
      local  = options[:local]
      from   = options[:from]

      $stderr.print path if monitor?  # debugging

      # absolute, home or current path
      #
      # NOTE: Ideally we would try to find a matching path among avaliable libraries
      # so that the library can be activated, however this would probably add a 
      # too much overhead and will by mostly a YAGNI, so we forgo any such
      # functionality, at least for now. 
      case path[0,1]
      when '/', '~', '.'
        $stderr.puts "  (absolute)" if monitor?  # debugging
        return nil
      end

      # from explicit library
      if from
        return find_library_feature(from, path, options)
      end

      # check the load stack (TODO: just last or all?)
      if local
        if last = $LOAD_STACK.last
        #$LOAD_STACK.reverse_each do |feature|
          lib = last.library
          if ftr = lib.find(path, options)
            unless $LOAD_STACK.include?(ftr)  # prevent recursive loading
              $stderr.puts "  (2 stack)" if monitor?  # debugging
              return ftr
            end
          end
        end
      end

      name, fname = ::File.split_root(path)

      # if the head of the path is the library
      if fname
        if name == 'ruby'  # part of the ruby hack
          return find_library_feature('ruby', fname, options)
        else
          lib = Library[name]
          if lib && ftr = lib.find(path, options) || lib.find(fname, options)
            $stderr.puts "  (3 indirect)" if monitor?  # debugging
           return ftr
          end
        end
      end

      # plain library name?
      if !fname && lib = Library.instance(path)
        if ftr = lib.default  # default feature to load
          $stderr.puts "  (5 plain library name)" if monitor?  # debugging
          return ftr
        end
      end

      # fallback to brute force search
      #if search #or legacy
        #options[:legacy] = true
        if ftr = find_any(path, options)
          $stderr.puts "  (6 brute search)" if monitor?  # debugging
          return ftr
        end
      #end

      $stderr.puts "  (7 fallback)" if monitor?  # debugging

      nil
    end

    #
    #
    #
    def find_library_feature(lib, path, options={})
      case lib
      when Library
      when :ruby, 'ruby'
        lib = RubyLibrary.singleton  # sort of a hack to let rubygems edge in
      else                           # b/c if RubyLibary is in the regular ledger
        lib = library(lib)           # then it prevents gems working for anything 
      end                            # with the same name in ruby site locations.
      ftr = lib.find(path, options)
      raise LoadError, "no such file to load -- #{path}" unless ftr
      $stderr.puts "  (direct)" if monitor?  # debugging
      return ftr
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
      options = options.merge(:main=>true)

      latest = options[:latest]

      # TODO: Perhaps the selected and unselected should be kept in separate lists?
      unselected, selected = *partition{ |name, libs| Array === libs }

      # broad search of pre-selected libraries
      selected.each do |(name, lib)|
        if ftr = lib.find(path, options)
          next if Library.load_stack.last == ftr
          return ftr
        end
      end

      # finally a broad search on unselected libraries
      unselected.each do |(name, libs)|
        libs = libs.sort
        libs = [libs.first] if latest
        libs.each do |lib|
          ftr = lib.find(path, options)
          return ftr if ftr
        end
      end

      nil
    end

    #
    # Brute force search looks through all libraries for matching features.
    # This is the same as #find_any, but returns a list of matches rather
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
    def search(path, options={})
      options = options.merge(:main=>true)

      latest = options[:latest]

      matches = []

      # TODO: Perhaps the selected and unselected should be kept in separate lists?
      unselected, selected = *partition{ |name, libs| Array === libs }

      # broad search of pre-selected libraries
      selected.each do |(name, lib)|
        if ftr = lib.find(path, options)
          next if Library.load_stack.last == ftr
          matches << ftr
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
      latest = options[:latest]

      matches = []

      each do |name, libs|
        case libs
        when Array
          libs = libs.sort
          libs = [libs.first] if latest
        else
          libs = [libs]
        end
          
        libs.each do |lib|
          lib.loadpath.each do |path|
            find = File.join(lib.location, path, match)
            list = Dir.glob(find)
            list = list.map{ |d| d.chomp('/') }
            matches.concat(list)
          end
        end
      end

      matches
    end

    #
    # Reduce the ledger to only those libraries the given library requires.
    #
    # @param [String] name
    #   The name of the primary library.
    #
    # @param [String] constraint
    #   The version constraint string.
    #
    # @return [Ledger] The ledger.
    #
    def isolate(name, constraint=nil)
      library = activate(name, constraint)

      # TODO: shouldn't this be done in #activate ?
      acivate_requirements(library)

      unused = []
      each do |name, libs|
        ununsed << name if Array === libs
      end
      unused.each{ |name| @table.delete(name) }

      self
    end

    #
    # Load up the ledger with a given set of paths and add an instance of
    # the special `RubyLibrary` class after that.
    #
    # @param [Array] paths
    #
    # @option paths [Boolean] :expound
    #   Expound on path entires. See {#expound_paths}.
    #
    # @return [Ledger] The primed ledger.
    #
    def prime(*paths)
      options = Hash === paths.last ? paths.pop : {}

      paths = expound_paths(*paths) if options[:expound]

require 'library/rubylib'  # TODO: What's the reason rubylib.rb is loaded here?

      paths.each do |path|
        begin
          add_location(path) if library_path?(path)
        rescue => err
          $stderr.puts err.message if ENV['debug']
        end
      end

      # We can not do this b/c it prevents gems from working
      # when a file has the same name as something in the
      # ruby lib or site locations. For example, if we intsll
      # the test-unit gem and require `test/unit`. Of course,
      # it Ruby ever adopted the "Rolls Way" then this could
      # be restored.
      #add_library(RubyLibrary.new)

      self
    end

  private

    #
    # For flexible priming, this method can be used to recursively
    # lookup library locations.
    #
    # If a given path is a file, it will considered a lookup "roll",
    # such that each line entry in the file is considered another
    # path to be expounded upon.
    #
    # If a given path is a directory, it will be returned if it
    # is a valid Ruby library location, otherwise each subdirectory
    # will be checked to see if it is a valid Ruby library location,
    # and returned if so.
    #
    # If, on the other hand, a given path is a file glob pattern,
    # the pattern will be expanded and those paths will expounded
    # upon in turn.
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
            subpaths = Dir.glob(File.join(entry, '*/'))
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
      dotindex(path) || (ENV['RUBYLIBS_GEMSPEC'] && gemspec(path))
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

        acivate_requirements(library, development, checklist) unless checklist[library]
      end

      self
    end

    #
    # If the directory has a `.index` file return it, otherwise +nil+.
    #
    def dotindex(path)
      file = File.join(path, '.index')
      File.file?(file) ? file : false
    end

    alias :dotindex? :dotindex

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
      glob = File.file?(File.join(path, '{,*}.gemspec'))
      Dir[glob].first
    end

    # TODO: Would it be faster to determine gem?(path) if we just compared
    # it to GEM_HOME? Then if it was, we could find the gemspec file.

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
