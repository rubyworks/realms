require 'roll/version'
require 'roll/metadata'
require 'roll/environment'

module Roll

  # = Library class
  #
  class Library

    # Dynamic link extension.
    #DLEXT = '.' + ::Config::CONFIG['DLEXT']

    #
    SUFFIXES = ['', '.rb', '.rbw', '.so', '.bundle', '.dll', '.sl', '.jar']

    #
    SUFFIX_PATTERN = "{#{SUFFIXES.join(',')}}"

    # Get an instance of a library by name, or name and version.
    # Libraries are singleton, so once loaded the same object is
    # always returned.

    def self.instance(name, constraint=nil)
      name = name.to_s
      #raise "no library -- #{name}" unless ledger.include?(name)
      return nil unless ledger.include?(name)

      library = ledger[name]

      if Library===library
        if constraint # TODO: it's okay if constraint fits current
          raise VersionConflict, "previously selected version -- #{ledger[name].version}"
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

    # A shortcut for #instance.

    def self.[](name, constraint=nil)
      instance(name, constraint)
    end

    # Same as #instance but will raise and error if the library is
    # not found. This can also take a block to yield on the library.

    def self.open(name, constraint=nil) #:yield:
      lib = instance(name, constraint)
      unless lib
        raise LoadError, "no library -- #{name}"
      end
      yield(lib) if block_given?
      lib
    end

    #
    def initialize(location, name=nil)
      @location = location
      @name     = name
    end

    #
    def location
      @location
    end

    # Access to metadata.
    def metadata
      @metadata ||= Metadata.new(location)
    end

    #
    def name
      @name ||= metadata.name
    end

    #
    def version
      @version ||= metadata.version
    end

    #
    def active?
      true #@active ||= metadata.active
    end

    #
    def loadpath
      @loadpath ||= metadata.loadpath
    end

    #
    def requires
      @requires ||= metadata.requires
    end

    #
    def released
      @released ||= metadata.released
    end

    # TODO
    def verify
      requires.each do |(name, constraint)|
        Library.open(name, constraint)
      end
    end

    # Find first matching +file+.

    #def find(file, suffix=true)
    #  case File.extname(file)
    #  when *SUFFIXES
    #    find = File.join(lookup_glob, file)
    #  else
    #    find = File.join(lookup_glob, file + SUFFIX_PATTERN) #'{' + ".rb,#{DLEXT}" + '}')
    #  end
    #  Dir[find].first
    #end

    # Standard loadpath search.
    #
    def find(file, suffix=true)
      lp = loadpath
      if suffix
        SUFFIXES.each do |ext|
          lp.each do |lpath|
            f = File.join(location, lpath, file + ext)
            return f if File.file?(f)
          end
        end
      else
        lp.each do |lpath|
          f = File.join(location, lpath, file)
          return f if File.file?(f)
        end
      end
      nil
    end

    # Does this library have a matching +file+? If so, the full-path
    # of the file is returned.
    #
    # Unlike #find, this also matches within the library directory
    # itself, eg. <tt>lib/foo/*</tt>. It is used by #acquire.
    def include?(file, suffix=true)
      lp = loadpath
      if suffix
        SUFFIXES.each do |ext|
          lp.each do |lpath|
            f = File.join(location, lpath, name, file + ext)
            return f if File.file?(f)
            f = File.join(location, lpath, file + ext)
            return f if File.file?(f)
          end
        end
      else
        lp.each do |lpath|
          f = File.join(location, lpath, name, file)
          return f if File.file?(f)
          f = File.join(location, lpath, file)
          return f if File.file?(f)
        end
      end
      nil
    end

    #def include?(file)
    #  case File.extname(file)
    #  when *SUFFIXES
    #    find = File.join(lookup_glob, "{#{name}/,}" + file)
    #  else
    #    find = File.join(lookup_glob, "{#{name}/,}" + file + SUFFIX_PATTERN) #'{' + ".rb,#{DLEXT}" + '}')
    #   end
    #  Dir[find].first
    #end

    #
    def require(file)
      if path = include?(file)
        require_absolute(path)
      else
        load_error = LoadError.new("no such file to require -- #{name}:#{file}")
        raise clean_backtrace(load_error)
      end
    end

    # NOT SURE ABOUT USING THIS
    def require_absolute(file)
      #Library.load_monitor[file] << caller if $LOAD_MONITOR
      Library.load_stack << self
      begin
        success = roll_original_require(file)
      #rescue LoadError => load_error
      #  raise clean_backtrace(load_error)
      ensure
        Library.load_stack.pop
      end
      success
    end

    #
    def load(file, wrap=nil)
      if path = include?(file, false)
        load_absolute(path, wrap)
      else
        load_error = LoadError.new("no such file to load -- #{name}:#{file}")
        clean_backtrace(load_error)
      end
    end

    #
    def load_absolute(file, wrap=nil)
      #Library.load_monitor[file] << caller if $LOAD_MONITOR
      Library.load_stack << self
      begin
        success = roll_original_load(file, wrap)
      #rescue LoadError => load_error
      #  raise clean_backtrace(load_error)
      ensure
        Library.load_stack.pop
      end
      success
    end

    # Inspection.
    def inspect
      if version
        %[#<Library #{name}/#{@version} @location="#{location}">]
      else
        %[#<Library #{name} @location="#{location}">]
      end
    end

    def to_s
      inspect
    end

    # Compare by version.
    def <=>(other)
      version <=> other.version
    end

#    # List of subdirectories that are searched when loading.
#    #--
#    # This defualts to ['lib/{name}', 'lib']. The first entry is
#    # usually proper location; the latter is added for default
#    # compatability with the traditional require system.
#    #++
#    def libdir
#      loadpath.map{ |path| File.join(location, path) }
#    end
#
#    # Does the library have any lib directories?
#    def libdir?
#      lib.any?{ |d| File.directory?(d) }
#    end

    # Location of executable. This is alwasy bin/. This is a fixed
    # convention, unlike lib/ which needs to be more flexable.
    def bindir  ; File.join(location, 'bin') ; end

    # Is there a <tt>bin/</tt> location?
    def bindir? ; File.exist?(bindir) ; end

    # Location of library system configuration files.
    # This is alwasy the <tt>etc/</tt> directory.
    def confdir ; File.join(location, 'etc') ; end

    # Is there a <tt>etc/</tt> location?
    def confdir? ; File.exist?(confdir) ; end

    # Location of library shared data directory.
    # This is always the <tt>data/</tt> directory.
    def datadir ; File.join(location, 'data') ; end

    # Is there a <tt>data/</tt> location?
    def datadir? ; File.exist?(datadir) ; end

  private

    #
    #def lookup_glob
    #  @lookup_glob ||= File.join(location, '{' + loadpath.join(',') + '}')
    #end

    #
    def clean_backtrace(error)
      if $DEBUG
        error
      else
        bt = error.backtrace
        bt = bt.reject{ |e| /roll/ =~ e } if bt
        error.set_backtrace(bt)
        error
      end
    end

    # Ledger augments the Library metaclass.
    class << self
      # Instance of Ledger class.
      def ledger
        @ledger ||= Ledger.new
      end

      # Current environment
      def environment
        ledger.environment
      end

      # List of library names.
      def list
        ledger.names
      end

      #
      def require(path)
        ledger.require(path)
      end

      #
      def load(path, wrap=nil)
        ledger.load(path, wrap)
      end

      #
      def acquire(path, opts={})
        ledger.acquire(path, opts)
      end

      #
      def load_stack
        ledger.load_stack
      end

      ## NOTE: Not used yet.
      #def load_monitor
      #  ledger.load_monitor
      #end
    end
  end

  # = Ledger class
  #
  class Ledger

    include Enumerable

    #
    def initialize
      @index = Hash.new{|h,k| h[k] = []}

      @environment = Environment.new

      @environment.each do |name, paths|
        paths.each do |path|
          unless File.directory?(path)
            warn "invalid path for #{name} -- #{path}"
            next
          end
          lib = Library.new(path, name)
          @index[name] << lib if lib.active?
        end
      end

      @load_stack = []
      #@load_monitor = Hash.new{ |h,k| h[k]=[] }
    end

    #
    def enironment
      @environment
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

    ## NOTE: Not used yet.
    #def load_monitor
    #  @load_monitor
    #end

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
      #return if $".include?(path)
      #return if $".include?(path+'.rb')

      lib, file = *match(path)
      if lib && file
        constrain(lib)
        lib.require_absolute(file)
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
      lib, file = *match(path, false)
      if lib && file
        constrain(lib)
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
        lib ? lib.load(file) : roll_original_load(file)
      else
        lib ? lib.require(file) : roll_original_require(file)
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

      return nil if /^\// =~ path  # absolute path

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

  # VersionError is raised when a requested version cannot be found.
  class VersionError < ::RangeError  # :nodoc:
  end

  # VersionConflict is raised when selecting another version
  # of a library when a previous version has already been selected.
  class VersionConflict < ::LoadError  # :nodoc:
  end

end

