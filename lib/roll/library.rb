require 'roll/metadata'
require 'roll/requirements'

module Roll

  # = Library class encapsulates a location on disc that contains a Ruby
  # project... with loadable lib files, of course.
  class Library

    # Current ledger.
    def self.ledger
      $LEDGER ||= Ledger.new
    end

    # A shortcut for #instance.
    def self.[](name, constraint=nil)
      instance(name, constraint)
    end

    # Get an instance of a library by name, or name and version.
    # Libraries are singleton, so once loaded the same object is
    # always returned.
    def self.instance(name, constraint=nil)
      ledger.library(name, constraint=nil)
    end

    # Same as #instance but will raise and error if the library is
    # not found. This can also take a block to yield on the library.
    def self.open(name, constraint=nil, &block)
      ledger.open(name, constraint, &block)
    end

    #
    def self.require(file)
      ledger.require(file)
    end

    #
    def self.load(file, wrap=nil)
      ledger.load(file, wrap)
    end

    #
    def self.autoload(constant, file)
      ledger.autoload(constant, file)
    end

    # Redirect methods called against Library to current Ledger.
    def self.method_missing(s, *a, &b)
      if ledger.respond_to?(s)
        ledger.send(s, *a, &b)
      else
        super(s, *a, &b)
      end
    end

    # Dynamic link extension.
    #DLEXT = '.' + ::Config::CONFIG['DLEXT']

    # TODO: Some extensions are platform specific --only
    # add the ones needed for the current platform.
    SUFFIXES = ['.rb', '.rbw', '.so', '.bundle', '.dll', '.sl', '.jar', '']

    # Extensions glob, joins extensions with comma and wrap in curly brackets.
    SUFFIX_PATTERN = "{#{SUFFIXES.join(',')}}"


    # New Library object.
    #
    # TODO: Place name into options.
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

end

