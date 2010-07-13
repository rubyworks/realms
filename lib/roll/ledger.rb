module Roll

  # = Ledger class
  #
  # The ledger encapsulates the behaviors of Library's metaclass.
  #
  class Ledger

    include Enumerable

    #
    def initialize
      @index = Hash.new{|h,k| h[k] = []}

      @index['ruby'] = RubyLibrary.new

      @environment = Environment.new

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

      @autoload_paths = []
    end

    #
    def environment
      @environment
    end

    #
    def index
      @index
    end


    #
    def [](name)
      @index[name]
    end

    #
    def []=(name, value)
      @index[name] = value
    end

    #
    def include?(name)
      @index.include?(name)
    end

    #
    def names
      @index.keys
    end

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

    # Stores an array of paths of which libraries were set to autoload.
    def autoload_paths
      @autoload_paths
    end

    ## NOTE: Not used yet.
    #def load_monitor
    #  @load_monitor
    #end

    # This is part of a hack to deal with the fact that autoload does not use
    # normal #require. So Rolls has to go ahead and load them upfront.
    def autoload(constant, fname)
      autoload_paths << fname
      #autoload_without_rolls(constant, fname)
      require(fname)
    end

    #--
    # The BIG QUESTION: Should Ruby's underlying require
    # be tried first then fallback to Rolls. Or vice-versa?
    #
    #  begin
    #    original_require(path)
    #  rescue LoadError => load_error
    #    lib, file = *match(path)
    #    if lib && file
    #      constrain(lib)
    #      lib.require_absolute(file)
    #    else
    #      raise clean_backtrace(load_error)
    #    end
    #  end
    #++

    #
    def require(path)
      return false if load_cache[path]
      return false if autoload_paths.include?(path)
      #return false if $".include?(path)

      lib, file = *match(path)
      if lib && file
        constrain(lib)
        load_cache[path] = [lib, file]
        success = lib.require_absolute(file)
        $" << path # not sure if neccessary (1.8 though may need it)
        success
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
      lib, file = load_cache[path]
      return lib.load_absolute(file, wrap) if lib

      lib, file = *match(path, false)
      if lib && file
        constrain(lib)
        load_cache[path] = [lib, file]
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
      cmp = self[lib.name]
      if Array === cmp
        self[lib.name] = lib
      else
        if lib.version != cmp.version
          raise VersionError
        end
      end
    end

  private

    # Find require matches.
    def match(path, suffix=true)
      path = path.to_s

      # Ruby appears to have a special exception for enumerator!!!
      return nil if path == 'enumerator' 

      # absolute path
      return nil if /^\// =~ path

      if path.index(':') # a specified library
        name, path = path.split(':')
        lib = Library.open(name)
        if lib.active?
          #file = lib.find(File.join(name,path), suffix)
          file = lib.include?(path, suffix)
          return lib, file
        end
      end

      matches = []

      # try the load stack first
      load_stack.reverse_each do |lib|
        if file = lib.find(path, suffix)
          return [lib, file] unless $VERBOSE
          matches << [lib, file]
        end
      end

      # if the head of the path is the library
      name, *_ = path.split(/\/|\\/)
      lib = Library[name]
      if lib && lib.active?
        if file = lib.find(path, suffix)
          return [lib, file] unless $VERBOSE
          matches << [lib, file]
        end
      end

      # try ruby
      lib = Library['ruby']
      if file = lib.find(path, suffix)
        return [lib, file] unless $VERBOSE
        matches << [lib, file]
      end

      # TODO: Perhaps the selected and unselected should be kept in separate lists?
      unselected, selected = *@index.partition{ |name, libs| Array === libs }

      # broad search pre-selected libraries
      selected.each do |(name, lib)|
        if file = lib.find(path, suffix)
          #matches << [lib, file]
          #return matches.first unless $VERBOSE
          return [lib, file] unless $VERBOSE
          matches << [lib, file]
        end
      end

      # finally try a broad search on unselected libraries
      unselected.each do |(name, libs)|
        pos = []
        libs.each do |lib|
          if file = lib.find(path, suffix)
            pos << [lib, file]
          end
        end
        unless pos.empty?
          latest = pos.sort{ |a,b| b[0].version <=> a[0].version }.first
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

    #
    def warn(message)
      $stderr.puts("roll: #{message}") if $DEBUG || $VERBOSE
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

  end#class Ledger

end
