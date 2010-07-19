require 'roll/config'
require 'roll/version'
require 'roll/environment'
require 'roll/library'
require 'roll/ruby'

module Roll

  # The Library Ledger, keeping track the an environment and
  # disptching the roll calls.
  #
  class Ledger

    include Enumerable

    MONITOR = ENV['ROLL_MONITOR']

    # Setup if the library ledger.
    #
    def initialize(name=nil)
      require_without_rolls 'roll/ruby'

      @load_stack = []
      @load_cache = {}

      @index = Hash.new{|h,k| h[k] = []}

      #- current environment if name is +nil+.
      @environment = Environment.new(name)

      @environment.each do |name, paths|
        paths.each do |path, loadpath|
          unless File.directory?(path)
            warn "invalid path for #{name} -- #{path}"
            next
          end
          # TODO: valid project directory?
          lib = Library.new(path, :name=>name, :loadpath=>loadpath)
          @index[name] << lib #unless lib.omit?
        end
      end

      # TODO: fallback measure would put all libs on loadpath ?
      #if ENV['ROLLOLD']
      #  @index.each do |name, libs|
      #    sorted_libs = [libs].flatten.sort
      #    lib = sorted_libs.first
      #    lib.loadpath.each do |lp|
      #      $LOAD_PATH.unshift(File.join(lib.location, lp))
      #    end
      #  end
      #end

      @index['ruby'] = RubyLibrary.new

      #@load_monitor = Hash.new{ |h,k| h[k]=[] }
    end

    #
    # TODO: object_hexid
    def inspect
      "#<Roll::Ledger:#{object_id} #{environment.name} (#{size})>"
    end

    # Get an instance of a library by name, or name and version.
    # Libraries are singleton, so once loaded the same object is
    # always returned.
    def library(name, constraint=nil)
      name = name.to_s
      #raise "no library -- #{name}" unless include?(name)
      return nil unless include?(name)

      library = index[name]

      if Library===library
        if constraint # FIXME: it's okay if constraint fits current
          raise VersionConflict, "previously selected version -- #{library.version}"  # ledger[name]
        else
          library
        end
      else # library is an array of versions
        if constraint
          compare = Version.constraint_lambda(constraint)
          library = library.select{ |lib| compare[lib.version] }.max
        else
          library = library.max
        end
        unless library
          raise VersionError, "no library version -- #{name} #{constraint}"
        end
        #index[name] = library #constrain(library)
        library.activate
        return library
      end
    end

    # Same as #library but will raise and error if the library is
    # not found. This can also take a block to yield on the library.
    def open(name, constraint=nil) #:yield:
      library = library(name, constraint)
      unless library
        raise LoadError, "no library -- #{name}"
      end
      yield(library) if block_given?
      library
    end

    # Activate a library by putting it's loadpaths on the master $LOAD_PATH.
    # This is neccessary only for the fact that autoload will not utilize
    # customized require methods.
    #
    # THINK: Should we also constrain the library here? My only hesitation
    # to that is we do not have direct access the ledger object, but would
    # have to use $LEDGER.
    def activate(library)
      lib = $LEDGER.index[name]
#p lib
      if Library === lib
        raise VersionConflict if lib != self
      else
        library.absolute_loadpath.each do |path|
          $LOAD_PATH.unshift(path)
        end

        $LEDGER.index[name] = library

        if library.requirements.exist?
          library.requirements.verify(true)
          # complete collapse
        end
      end
    end

    # Get environment.
    #
    # name - Optional name of the environemnt. [to_s]
    #
    # Returns the current Environment. If name is given, returns the
    # environment by that name.
    def environment
      @environment
    end
 
    # Returns an hash of `name => library` or `name => [ libvN, libv2, ...]`.
    def index ; @index ; end

    # Does the ledger include a library by the given +name+?
    def include?(name)
      @index.include?(name)
    end

    # Returns a list of all the library names.
    def names
      @index.keys
    end

    #
    alias_method :list, :names

    # Iterate through each library set.
    def each(&block)
      @index.each(&block)
    end

    # Number of library sets.
    def size
      @index.size
    end

    # Array keeps track of currely loading libraries.
    def load_stack
      @load_stack
    end

    # Hash that stores which paths have already been loaded.
    def load_cache
      @load_cache
    end

    ## NOTE: Not used yet.
    #def load_monitor
    #  @load_monitor
    #end

    # Constrain a library to a single version. This means, if anyone tries
    # to use a different version once a library has been constrained, an
    # VersionConflict error will be raised.
    def constrain(lib)
      cmp = index[lib.name]
      if Array === cmp
        index[lib.name] = lib
      else
        if lib.version != cmp.version
          raise VersionError
        end
      end
    end

    # Roll-style loading. First it looks for a specific library via `:`.
    # If `:` is not present it then tries the current library. Failing that
    # it fallsback to Ruby itself.
    #
    #   require('facets:string/margin')
    #
    # To "load" the library, rather than "require" it, set the +:load+
    # option to true.
    #
    #   require('facets:string/margin', :load=>true)
    #
    # TODO: Should we also check $"? Eg. `return false if $".include?(path)`.
    def require(path, options={})
      if file = load_cache[path]
        if options[:load]
          file.load
        else
          return false
        end
      end

      if file = find(path, options)
        constrain(file.library)
        load_cache[path] = file
        return file.acquire(options)
      end

      if options[:load]
        load_without_rolls(path, options[:wrap])
      else
        require_without_rolls(path)
      end
    end

    # Load file path. This is just like #require except that previously
    # loaded files will be reloaded and standard extensions will not be
    # automatically appended.
    #
    # TODO: maybe swap #load and #require ?
    def load(path, options={})
      options[:load]   = true
      options[:suffix] = false
      require(path, options)
    end

    # Legacy require.
    def require_legacy(path)
      require(path, :legacy=>true)
    end

    # Legacy loading.
    def load_legacy(path, wrap=nil)
      load(path, :legacy=>true, :wrap=>wrap)
    end

=begin
    #
    def legacy_require(path)
      return false if load_cache[path]
      return false if $".include?(path)

      file = match(path) || search(path)
      if file
        lib = file.library
        constrain(lib)
        load_cache[path] = file
        file.require
      else
        begin
          roll_original_require(path)
        rescue LoadError => load_error
          raise clean_backtrace(load_error)
        end
      end
    end

    #
    def legacy_load(path, wrap=nil)
      file = load_cache[path]
      return file.library.load_absolute(file, wrap) if file

      file = match(path, :suffix=>false) || search(path, :suffix=>false)
      if file
        lib = file.library
        constrain(lib)
        load_cache[path] = file
        lib.load_absolute(file, wrap)
      else
        begin
          roll_original_load(path, wrap)
        rescue LoadError => load_error
          raise clean_backtrace(load_error)
        end
      end
    end
=end

    #
    def match(path, opts={})
      find(path, opts)
    end

    # Find matching libary files. This is the "mac daddy" method used by
    # the #require and #load methods to find the sepcified +path+ among
    # the various libraries and their loadpaths.
    def find(path, options={})
      path   = path.to_s

      suffix = options[:suffix]
      search = options[:search]
      legacy = options[:legacy]

print path if MONITOR

      # Ruby appears to have a special exception for enumerator!!!
      #return nil if path == 'enumerator' 

      # TODO: absolute path ???
      if /^\// =~ path
        return nil
      end

      if path.index(':') # a specified library
        name, path = path.split(':')
        lib = Library.open(name)
        file = lib.include?(path, options)
puts "  (1 direct)" if MONITOR
        return file
      end

      # try the load stack (TODO: just last or all?)
      load_stack.reverse_each do |lib|
        if file = lib.include?(path, options)
puts "  (2 stack)" if MONITOR
          return file
        end
      end
      #last = load_stack.last
      #if last && file = last.include?(file)
      #  return file
      #end

      # if the head of the path is the library
      if path.index('/') or path.index('\\')
        name, *_ = path.split(/\/|\\/)
        lib = Library[name]
        if lib && file = lib.include?(path, options)
puts "  (3 indirect)" if MONITOR
          return file
        end
      end

      # try ruby
      lib = Library['ruby']
      if file = lib.include?(path, options)
puts "  (4 ruby core)" if MONITOR
        return file
      end
 
      # a plain library name?
      if !path.index('/') && lib = Library.instance(path)
        if file = lib.default # default file to load
puts "  (5 plain library name)" if MONITOR
          return file
        end
      end

      # if fallback to brute force search
      if search or legacy
        result = search(path, options)
puts "  (6 brute search)" if MONITOR
        return result if result
      end

puts "  (7 fallback)" if MONITOR
      nil
    end

    # Brute force search looks through all libraries for a matching file.
    #
    # path    - file path for which to search
    # options: 
    #   :select -
    #   :suffix -
    #   :legacy -
    #
    # Returns either
    def search(path, options={})
      matches = []
      select  = options[:select]

      # TODO: Perhaps the selected and unselected should be kept in separate lists?
      unselected, selected = *@index.partition{ |name, libs| Array === libs }

      #- broad search pre-selected libraries
      selected.each do |(name, lib)|
        if file = lib.find(path, options)
          return file unless select #$VERBOSE
          matches << file
        end
      end

      #- finally try a broad search on unselected libraries
      unselected.each do |(name, libs)|
        pos = []
        libs.each do |lib|
          if file = lib.find(path, options)
            pos << file
          end
        end
        unless pos.empty?
          latest = pos.sort{ |a,b| b.library.version <=> a.library.version }.first
          return latest unless select #$VERBOSE
          matches << latest
          #return matches.first unless $VERBOSE
        end
      end

      #- last ditch attempt, search $LOAD_PATH
      # ???

      matches.uniq!
      #warn_multiples(path, matches) if matches.size > 1
      select ? matches.first : matches
    end

    # Issue warning about multiple matches.
    def warn_multiples(path, matches)
      warn "multiple matches for same request -- #{path}"
      matches.each do |file|
        warn "  #{file}"
      end
    end

    # Issue a warning form rolls.
    def warn(message)
      $stderr.puts("roll: #{message}") if $DEBUG || $VERBOSE
    end

    # Take an +error+ and remove any mention of 'roll' from it's backtrace.
    # Will leave the backtrace untouched if $DEBUG is set to true.
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

  public

    # -- T O O L S --

    # Change current environment.
    #def use(name)
    #  Environment.use(name)
    #end

    #
    def env(name)
      if name
        Environment.new(name)
      else
        @environment #Environment.current
      end
    end

    # Return Array of environment names.
    def environments
      Environment.list
    end

    # Synchronize an environment by +name+. If a +name+
    # is not given the current environment is synchronized.
    def sync(name=nil)
      env = env(name)
      env.sync
      env.save
    end

    # Check to see if an environment is in-sync by +name+. If a +name+
    # is not given the current environment is checked.
    def check(name=nil)
      env = env(name)
      env.index == env.lookup_index
    end

    # Automtically add .ruby/ entries to projects, where possible.
    # TODO: rename (or remove) this.
    def prep(name=nil)
      env = env(name)
      env.prep
    end

    # Add path to current environment.
    def insert(path, depth=3)
      env.append(path, depth)
      env.sync
      env.save
      return path, env.file
    end

    # Alias for #insert.
    alias_method :in, :insert

    # Remove path from current environment.
    def remove(path)
      env.delete(path)
      env.sync
      env.save
      return path, env.file
    end

    # Alias for #remove.
    alias_method :out, :remove

    # Go thru each roll lib and collect bin paths.
    def path
      binpaths = []
      list.each do |name|
        lib = library(name)
        if lib.bindir?
          binpaths << lib.bindir
        end
      end
      binpaths
    end

    # Verify dependencies are in current environment.
    #--
    # TODO: Instead of Dir.pwd, lookup project root.
    #++
    def verify(name=nil)
      if name
        open(name).verify
      else
        Library.new(Dir.pwd).verify
      end
    end

    # Sync environments that contain locations relative to the
    # current gem home.
    def sync_gem_environments
      resync = []
      environments.each do |name|
        env = environment(name)
        if env.has_gems?         
          resync << name
          env.sync
          env.save
        end
      end
      resync
    end

  end

end

