require 'roll/version'
require 'roll/metadata'
require 'roll/requirements'
require 'roll/environment'

#$MONITOR = ENV['ROLL_MONITOR']

module Roll

  # = Library class
  #
  class Library

    # Dynamic link extension.
    #DLEXT = '.' + ::Config::CONFIG['DLEXT']

    # TODO: Some extensions are platform specific --only
    # add the ones needed for the current platform.
    SUFFIXES = ['.rb', '.rbw', '.so', '.bundle', '.dll', '.sl', '.jar', '']

    # Extensions glob, joins extensions with comma and wrap in curly brackets.
    SUFFIX_PATTERN = "{#{SUFFIXES.join(',')}}"

    # Get an instance of a library by name, or name and version.
    # Libraries are singleton, so once loaded the same object is
    # always returned.
    def self.instance(name, constraint=nil)
      name = name.to_s
      #raise "no library -- #{name}" unless ledger.include?(name)
      return nil unless include?(name) #ledger.include?(name)

      library = index[name] #ledger[name]

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

    # New Library object.
    def initialize(location, name=nil, options={})
      @location = location
      @name     = name
      @options  = options
    end

    # Location of library files on disc.
    def location
      @location
    end

    # Access to metadata.
    def metadata
      @metadata ||= Metadata.new(@location, @name, @options)
    end

    #
    def requirements
      @requirements ||= Requirements.new(location)
    end

    # Is the library active?
    #
    # NOTE: Presently this is always +true+.
    def active?
      @active ||= metadata.active?
    end

    # Library's "unixname".
    def name
      @name ||= metadata.name
    end

    # Library's version number.
    def version
      metadata.version
    end

    # Library's internal load path(s). This will default to `['lib']`
    # not otherwise given.
    def loadpath
      metadata.loadpath
    end

    # Release date.
    def date
      metadata.date
    end

    # Alias for +#date+.
    alias_method :released, :date

    # List of dependencies taken from a REQUIRE file, if it exists.
    # This includes both neccessary and optional dependencies.
    #
    # FIXME: Currently this returns and empty array. To fix either add to the
    # Metadata class or create a new class that can parse the requirements
    # listed ina REQUIRE file, .gemspec, and/or Gemfile.
    def requires
      []
    end

    # Take each project dependency and open it. This will help reveal any
    # version conflicts or missing dependencies.
    def verify
      requires.each do |(name, constraint)|
        Library.open(name, constraint)
      end
    end

    # Standard loadpath search for the first matching +file+.
    # Set +suffix+ to false to prevent automatic extension matching.
    def find(file, suffix=true)
      lp = loadpath
      if suffix
        SUFFIXES.each do |ext|
          lp.each do |lpath|
            f = File.join(location, lpath, file + ext)
            if File.file?(f)
              return libfile(lpath, file, ext)
            end
          end
        end
      else
        lp.each do |lpath|
          f = File.join(location, lpath, file)
          if File.file?(f)
            return libfile(lpath, file, ext)
          end
        end
      end
      nil
    end

    # Create a new LibFile object from +lpath+, +file+ and +ext+.
    def libfile(lpath, file, ext)
      LibFile.new(self, lpath, file, ext) 
    end

    # LibFile class represents a single file in a library.
    class LibFile
      attr_reader :library, :loadpath, :filename, :extension
      def initialize(library, loadpath, filename, extension=nil)
        @library   = library
        @loadpath  = loadpath
        @filename  = filename
        @extension = extension
      end
      def location
        library.location
      end
      def fullname
        File.join(location, loadpath, filename + (extension || ''))
      end
      def localname
        File.join(filename + (extension || ''))
      end
      def to_s  ; fullname; end
      def to_str; fullname; end
      #
      def require
        return false if $".include?(localname)  # ruby 1.8 does not use absolutes
        #Library.load_monitor[file] << caller if $LOAD_MONITOR
        Library.load_stack << library
        begin
          success = roll_original_require(fullname)
        #rescue LoadError => load_error
        #  raise clean_backtrace(load_error)
        ensure
          Library.load_stack.pop
        end
        $" << localname # ruby 1.8 does not use absolutes
        success
      end
    end

    # Does this library have a matching +file+? This is almost the same
    # as #find, but unlike #find, this also matches within the library
    # directory itself, e.g. `lib/foo/*`. This method is used by #acquire.
    def include?(file, suffix=true)
      lp = loadpath
      if suffix
        SUFFIXES.each do |ext|
          lp.each do |lpath|
            f = File.join(location, lpath, name, file + ext)
            if File.file?(f)
              return LibFile.new(self, File.join(lpath, name), file, ext)
            end
            f = File.join(location, lpath, file + ext)
            if File.file?(f)
              return LibFile.new(self, lpath, file, ext)
            end
          end
        end
      else
        lp.each do |lpath|
          f = File.join(location, lpath, name, file)
          if File.file?(f)
            return LibFile.new(self, File.join(lpath, name), file)
          end
          f = File.join(location, lpath, file)
          if File.file?(f)
            return LibFile.new(self, lpath, file)
          end
        end
      end
      nil
    end

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
        %[#<Library #{name}/#{version} @location="#{location}">]
      else
        %[#<Library #{name} @location="#{location}">]
      end
    end

    # Same as #inspect.
    def to_s
      inspect
    end

    # Compare by version.
    def <=>(other)
      version <=> other.version
    end

    # Return default file. This is the file that has same name as the
    # library itself.
    def default
      @default ||= include?(name)
    end

    #--
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
    #++

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

    # Take an +error+ and remove any mention of 'roll' from it's backtrace.
    # Will leave the backtrace untouched if $DEBUG is set to true.
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

  end

  # Library metaclass acts as the library ledger, keeping track the
  # environment and disptching the roll calls.
  class << Library
    include Enumerable

    # Setup if the library ledger.
    #
    # TODO: Rename this method.
    def initialize
      roll_original_require 'roll/ruby'

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

    # Returns the current instance of the Environment class.
    def environment
      @environment
    end

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

    # Stores an array of paths of which libraries were set to autoload.
    #def autoload_paths
    #  @autoload_paths
    #end

    ## NOTE: Not used yet.
    #def load_monitor
    #  @load_monitor
    #end

    # This is part of a hack to deal with the fact that autoload does not use
    # normal #require. So Rolls has to go ahead and load them upfront.
    def autoload(constant, path)
      #autoload_paths << path
      #autoload_without_rolls(constant, fname)
      require(path)
    end

    #
    def require(path)
      return false if load_cache[path]
      #return false if autoload_paths.include?(path)
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

    # Get environment.
    def env(name=nil)
      if name
        env = Environment.new(name)
      else
        env = environment #Environment.new
      end
      env
    end

    # Change current environment.
    def use(name)
      Environment.use(name)
    end

    # Return Array of environment names.
    def environments
      Environment.list
    end

    # DEPRECATE
    def environment_index(name=nil)
      env(name).to_s_index
    end

    # Synchronize an environment by +name+. If a +name+
    # is not given the current environment is synchronized.
    def sync(name=nil)
      env = env(name)
      env.sync
      env.save
    end

    # Automtically add .ruby/ entries to projects, where possible.
    def prep(name=nil)
      env = env(name)
      env.prep
    end

    # Add path to current environment.
    def in(path, depth=3)
      #env = Environment.new

      env.append(path, depth)
      env.sync
      env.save

      return path, env.file
    end

    # Remove path from current environment.
    def out(path)
      #env = Environment.new

      env.delete(path)
      env.sync
      env.save

      return path, env.file
    end

    # Go thru each roll lib and collect bin paths.
    def path
      binpaths = []
      list.each do |name|
        lib = Library[name]
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
        Library.open(name).verify
      else
        Library.new(Dir.pwd).verify
      end
    end

  end

  class Library
    initialize
  end

end

