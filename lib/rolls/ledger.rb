module Rolls

  # Ledger class track available libraries by library name.
  # It is essentially a hash object, but with a special way
  # of storing them to track versions. Each have key is the
  # name of a library, as a String, and each value is either
  # a Library object, if that particular version is active,
  # or an Array of available versions of the library if inactive.
  #
  class Ledger

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
        entry = @table[library.name]

        case entry
        when NilClass
          raise "serious shit! nil entry in ledger table!"
        when Array
          entry << library unless entry.include?(library)
        else
          # Library is already active so compare and make sure they are the
          # same, otherwise warn. (Should this ever raise an error?)
$stderr.puts entry.inspect
$stderr.puts library.inspect
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
    # Get the most current library by name. This does not activate!
    #
    def current(name)
      Array(@table[name.to_s]).max
    end

    #
    # Replace current ledger with table from another.
    #
    def replace(ledger)
      case ledger
      when Ledger
        @table.replace(ledger.table)
      when Hash
        initialize  # reinitialize
        ledger.each do |name, value|
          raise TypeError unless Array === value || Library === value
          @table[name.to_s] = value
        end
      else
        raise TypeError
      end
    end

    #
    # Iterate over each ledger entry.
    #
    def each(&block)
      @table.each(&block)
    end

    #
    # Get a copy of the underlying table.
    #
    def to_h
      @table.dup
    end

    #
    # Size of the ledger is the number of libraries available.
    #
    # @return [Fixnum] Size of the ledger.
    #
    def size
      @table.size
    end

    # TODO: Seems like Ledger#key?, #keys and #values should have better names.

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
    alias :names :keys

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

      @table[name] = vers  #self[name] = vers
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
    # @todo Should we also check $"? Eg. `return false if $".include?(path)`.
    #       Consdider require_relative with this.
    #
    def activate(name, constraint=nil) #:yield:
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
          #verscon = Version::Constraint.parse(constraint)
          #library = library.select{ |lib| verscon.compare(lib.version) }.max
          library = constrain(name, constraint).max
        else
          library = library.max
        end
        unless library
          raise VersionError, "no library version -- #{name} #{constraint}"
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
    #   pathname of feature relative to library's loadpath
    #
    # @return [true,false] if feature was successfully loaded
    #
    def load(pathname, options={})
      unless Hash === options
        options = {}
        options[:wrap] = options 
      end
      options = options.rekey

      #if feature = $LOAD_CACHE[pathname]
      #  return feature.load if options[:load]
      #  return false if feature.required?
      #  return feature.require(options)
      #end

      if feature = find_feature(pathname, options)
        feature.load(options)
      else  # fallback to Ruby's load system
        feature = Library::LegacyFeature.new(pathname)
        $LOAD_CACHE[pathname] = feature
        success = feature.load(options)
      end
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
      options[:require] = true
      options[:suffix]  = true

      load(pathname, options)

      #if file = $LOAD_CACHE[path]
      #  return file.load
      #end

      #if file = Library.find(path, options)
      #  #file.library_activate
      #  $LOAD_CACHE[path] = file
      #  return file.load(options) #acquire(options)
      #end

      ##if options[:load]
      #  load_without_library(path, options[:wrap])
      ##else
      ##  require_without_library(path)
      ##end
    end

    #
    # Require from current library.
    #
    # @param pathname [String]
    #   Pathname of feature relative to current library's loadpath.
    #
    # @return [true, false] If feature is newly required.
    #
    # @todo better name for `#require_local`?
    #
    def require_local(path, options={})
      if feature = find_local_feature(path, options)
        $stderr.puts "#{path} (local)" if monitor?  # debugging
        return feature.require(options)
      end
    end

    #
    # Require from current library.
    #
    # @param pathname [String]
    #   Pathname of feature relative to current library's loadpath.
    #
    # @return [true, false] If feature is newly required.
    #
    alias_method :acquire, :require_local

    #
    # Find matching library features. This is the "mac daddy" method used by
    # the #require and #load methods to find the specified +path+ among
    # the various libraries and their load paths.
    #
    def find_feature(path, options={})
      path = path.to_s

      #suffix = options[:suffix]
      #search = options[:search]
      legacy = options[:legacy]

      ftr = $LOAD_CACHE[path]

      return ftr if ftr 

      $stderr.print path if monitor?  # debugging

      # absolute, home or current path
      #
      # NOTE: Ideally we would try to find a matching path among avaliable libraries
      # so that the library can be activated, however this would add extra overhead
      # overhead and will by mostly a YAGNI, so we forgo this functionality, at least for now. 
      case path[0,1]
      when '/', '~', '.'
        $stderr.puts "  (absolute)" if monitor?  # debugging
        # TODO: expand path and ensure it exists?
        ftr = Library::LegacyFeature.new(path)
        $LOAD_CACHE[path] = ftr
        return ftr
      end

      # Look in user paths, there include -I and RUBYLIB environment locations,
      # as well as manually added paths to $LOAD_PATH. Very hackish stuff!
      if userpath = Utils.find_userpath(path, options)
        return Library::LegacyFeature.new(userpath)
      end

      from, subpath = ::File.split_root(path)

      if from == 'ruby'  # ruby hack
        $stderr.puts "  (ruby)" if monitor?  # debugging
        #lib = RubyLibrary.singleton
        if subpath
          ftr = find_library_feature('ruby', subpath, options)
        else
          # what the hell is just `load 'ruby'` ;)
        end
      else
        if lib = key?(from) && activate(from)   # TODO: this activates, should it only do so if it has the feature? `Array(self[from]).max` instead?
          $stderr.puts "  (from)" if monitor?  # debugging
          if subpath  # library name with subpath (path == from)
            ftr = lib.find_feature(path, options) || lib.find_feature(subpath, options)
            # TODO: activate library here? if ftr?
          else  # just library name
            ftr = lib.default_feature
            # TODO: activate library here? if ftr?
          end
        end
      end

      return $LOAD_CACHE[path] = ftr if ftr

      # legacy brute force search
      # (This is very bad b/c it is the source of name clashes between libraries.)
      if legacy
        #options[:legacy] = true
        if ftr = find_any(path, options)
          $stderr.puts "  (6 legacy search)" if monitor?  # debugging
          return($LOAD_CACHE[path] = ftr)
        end
      end

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
        lib = RubyLibrary.singleton    # sort of a hack to let rubygems edge in
      else                             # b/c if RubyLibary is in the regular ledger
        lib = self[lib] #library(lib)  # then it prevents gems working for anything 
      end                              # with the same name in ruby site locations.
      ftr = lib.find_feature(path, options)
      raise LoadError, "no such file to load -- #{path}" unless ftr
      $stderr.puts "  (direct)" if monitor?  # debugging
      # TODO: activate library here if ftr?
      return ftr
    end

    #
    # Find a feature from the currently loading library.
    #
    def find_local_feature(path, options={})
      if lib = __LIBRARY__
        if ftr = lib.find(path, options)
          return nil if $LOAD_STACK.include?(ftr)  # prevent recursive loading
          return ftr
        end
      else
        # can this even happen?
        nil
      end
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
    # @return [Feature] Matching feature.
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
    # Load up the ledger with a given set of paths.
    #
    # @param [Array] paths
    #
    # @option paths [Boolean] :expound
    #   Expound on path entires. See {#expound_paths}.
    #
    # @return [Ledger] The primed ledger.
    #
    def loadup(*paths)
      options = Hash === paths.last ? paths.pop : {}

      @table = Hash.new(){ |h,k| h[k] = [] }

      paths = expound_paths(*paths) if options[:expound]

      #require 'library/rubylib'  # TODO: What's the reason rubylib.rb is loaded here?

      paths.each do |path|
        begin
          add(path) if library_path?(path)
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

    #
    # Like #loadup but empties the ledger table first.
    #
    # @param [Array] paths
    #
    # @option paths [Boolean] :expound
    #   Expound on path entires. See {#expound_paths}.
    #
    # @return [Ledger] The primed ledger.
    #
    def prime(*paths)
      @table = Hash.new(){ |h,k| h[k] = [] }
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
    # @return [Ledger] The ledger.
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

  protected

    #
    # Protected access to underlying table.
    #
    def table
      @table
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
