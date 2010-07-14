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

    #$MONITOR = ENV['ROLL_MONITOR']

    # Setup if the library ledger.
    #
    def initialize(name=nil)
      roll_original_require 'roll/ruby'

      @index = Hash.new{|h,k| h[k] = []}

      @index['ruby'] = RubyLibrary.new

      # -- current environment if name is +nil+.
      @environment = Environment.new(name)

      @environment.each do |name, paths|
        paths.each do |path, loadpath|
          unless File.directory?(path)
            warn "invalid path for #{name} -- #{path}"
            next
          end
          lib = Library.new(path, name, :loadpath=>loadpath)
          @index[name] << lib if lib.active?
        end
      end

      @load_stack = []
      @load_cache = {}

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
        if constraint # TODO: it's okay if constraint fits current
          raise VersionConflict, "previously selected version -- #{index[name].version}"  # ledger[name]
        else
          library
        end
      else # library is an array of versions
        if constraint
          compare = Version.constraint_lambda(constraint)
          library = library.select(&compare).max
        else
          library = library.max
        end
        unless library
          raise VersionError, "no library version -- #{name} #{constraint}"
        end
        #ledger[name] = library
        #library.activate
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

    # Get environment.
    #
    # name - Optional name of the environemnt. [to_s]
    #
    # Returns the current Environment. If name is given,
    # returns the environment by that name.
    def environment(name=nil)
      if name
        Environment.new(name)
      else
        @environment
      end
    end

    # DEPRECATE
    alias_method :env, :environment
 
    # Returns an hash of `name => library` or `name => [ libvN, libv2, ...]`.
    def index
      @index
    end

    #
    def include?(name)
      @index.include?(name)
    end

    #
    def names
      @index.keys
    end
    alias_method :list, :names

    #
    def each(&block)
      @index.each(&block)
    end

    #
    def size
      @index.size
    end

    #
    def load_stack
      @load_stack
    end

    #
    def load_cache
      @load_cache
    end

    ## NOTE: Not used yet.
    #def load_monitor
    #  @load_monitor
    #end

    # This is part of a hack to deal with the fact that autoload does not use
    # normal #require. So Rolls has to go ahead and load them upfront.
    def autoload(constant, path)
      #autoload_without_rolls(constant, fname)
      require(path)
    end

    #
    def require(path)
      return false if load_cache[path]
      return false if $".include?(path)

      file = match(path)
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
    def load(path, wrap=nil)
      file = load_cache[path]
      return file.library.load_absolute(file, wrap) if file

      file = match(path, false)
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

    # Acquire is pure Roll-style loading. First it
    # looks for a specific library via ':'. If ':' is
    # not present it then tries the current library.
    # Failing that it fallsback to Ruby itself.
    #
    #   acquire('facets:string/margin')
    #
    # To "load" the library, rather than "require" it set
    # the +:load+ option to true.
    #
    #   acquire('facets:string/margin', :load=>true)
    #
    def acquire(file, opts={})
      if file.index(':') # a specific library
        name, file = file.split(':')
        lib = Library.open(name)
        abs = lib.include?(file)
      else # try the current library
        cur = load_stack.last
        if cur && abs = cur.include?(file)
          lib = cur
        elsif !file.index('/') # is this a library name?
          if cur = Library.instance(file)
            lib = cur
            abs = lib.default # default file to load
          end
        end
      end
      if opts[:load]
        lib ? lib.load_absolute(abs) : roll_original_load(file)
      else
        lib ? lib.require_absolute(abs) : roll_original_require(file)
      end
    end

    #
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

  private

    # Find matching libary files. This is the "mac daddy" method used by
    # the #require and #load methods to find the sepcified +path+ among
    # the various libraries and their loadpaths.
    def match(path, suffix=true)
      path = path.to_s

#puts path if $MONITOR

      # Ruby appears to have a special exception for enumerator!!!
      return nil if path == 'enumerator' 

      # absolute path
      return nil if /^\// =~ path

#puts "  1. direct" if $MONITOR

      if path.index(':') # a specified library
        name, path = path.split(':')
        lib = Library.open(name)
        #if lib.active?
          #file = lib.find(File.join(name,path), suffix)
          file = lib.include?(path, suffix)
          return file
        #end
      end

      matches = []

#puts "  2. stack" if $MONITOR

      # try the load stack
      load_stack.reverse_each do |lib|
        if file = lib.find(path, suffix)
          return file unless $VERBOSE
          matches << file
        end
      end

#puts "  3. indirect" if $MONITOR

      # if the head of the path is the library
      name, *_ = path.split(/\/|\\/)
      lib = Library[name]
      if lib #&& lib.active?
        if file = lib.find(path, suffix)
          return file unless $VERBOSE
          matches << file
        end
      end

#puts "  4. rubycore" if $MONITOR

      # try ruby
      lib = Library['ruby']
      if file = lib.find(path, suffix)
        return file unless $VERBOSE
        matches << file
      end

#puts "  5. rest" if $MONITOR

      # TODO: Perhaps the selected and unselected should be kept in separate lists?
      unselected, selected = *@index.partition{ |name, libs| Array === libs }

      # broad search pre-selected libraries
      selected.each do |(name, lib)|
        if file = lib.find(path, suffix)
          return file unless $VERBOSE
          matches << file
        end
      end

      # finally try a broad search on unselected libraries
      unselected.each do |(name, libs)|
        pos = []
        libs.each do |lib|
          if file = lib.find(path, suffix)
            pos << file
          end
        end
        unless pos.empty?
          latest = pos.sort{ |a,b| b.library.version <=> a.library.version }.first
          return latest unless $VERBOSE
          matches << latest
          #return matches.first unless $VERBOSE
        end
      end

      matches.uniq!

      if matches.size > 1
        warn_multiples(path, matches)
      end

      matches.first
    end

    #
    def warn_multiples(path, matches)
      warn "multiple matches for same request -- #{path}"
      matches.each do |lib, file|
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
    def use(name)
      Environment.use(name)
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

    # Automtically add .ruby/ entries to projects, where possible.
    # TODO: rename (or remove) this.
    def prep(name=nil)
      env = env(name)
      env.prep
    end

    # Add path to current environment.
    def in(path, depth=3)
      env.append(path, depth)
      env.sync
      env.save
      return path, env.file
    end

    # Remove path from current environment.
    def out(path)
      env.delete(path)
      env.sync
      env.save
      return path, env.file
    end

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

  end

end
