module Roll
  require 'roll/environment'
  require 'roll/library'

  # = Ledger class
  #
  class Ledger

    include Enumerable

    #
    def initialize
      @index = Hash.new{|h,k| h[k] = []}

      environment = Environment.new

      environment.each do |name, paths|
        paths.each do |path|
          @index[name] << Library.new(path, name)
        end
      end

      @load_stack = []
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

    # TODO: Should Ruby's underlying require be tried first,
    # then fallback to Rolls. Or vice-versa as it is now.

    def require(path)
      lib, file = *match(path)
      if lib && file
        constrain(lib)
        lib.require_absolute(file)
      else
        Kernel.require(path)     # fallback to Ruby
      end
    end

    #
    def load(path, wrap=nil)
      lib, file = *match(path)
      if lib && file
        constrain(lib)
        lib.load_absolute(file, wrap)
      else
        Kernel.load(path, wrap)  # fallback to Ruby
      end
    end

    #--
    # This may no longer be neccessary becuase require and load
    # now check the load_stack first.
    #++

    # Use acquire to use Roll-style loading. This first
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
      else # try the current library
        cur = load_stack.last
        if cur && cur.include?(file)
          lib = cur
        elsif !file.index('/') # is this a library name?
          if cur = Library.instance(file)
            lib  = cur
            file = lib.default # default file to load
          end
        end
      end
      if opts[:load]
        lib ? lib.load(file) : Kernel.load(file)
      else
        lib ? lib.require(file) : Kernel.require(file)
      end
    end

    #
    def constrain(lib)
      if Array === self[lib.name]
        self[lib.name] = lib
      else
        if lib.version != self[lib.name].version
          raise VersionError
        end
      end
    end

  private

    # Find require matches.
    def match(path)
      matches = []

      if path.index(':') # a specific library
        name, path = path.split(':')
        lib  = Library.open(name)
        file = lib.include?(path)
        return lib, file
      end

      # try the load stack first
      load_stack.reverse_each do |lib|
        if file = lib.include?(path)
          matches << [lib, file]
          break
        end
      end

      if matches.empty?
        each do |name, libs|
          case libs
          when Array
            pos = []
            libs.each do |lib|
              if file = lib.include?(path)
                pos << [lib, file]
              end
            end
            unless pos.empty?
              latest = pos.sort{ |a,b| b[0].version <=> a[0].version }.first
              matches << latest
              break unless $VERBOSE #$WARN
            end
          else
            lib = libs
            if file = lib.include?(path)
              matches << [lib, file]
              break unless $VERBOSE
            end
          end
        end
        if matches.size > 1
          warn_multiples(path, matches)
        end
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

  end#class Ledger

end#module Roll

