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
    SUFFIXES = ['.rb', '.rbw', '.so', '.bundle', '.dll', '.sl', '.jar'] #, '']

    # Extensions glob, joins extensions with comma and wrap in curly brackets.
    SUFFIX_PATTERN = "{#{SUFFIXES.join(',')}}"

    # New Library object.
    #
    # TODO: Place name into options.
    def initialize(location, options={})
      @location = location
      @name     = options.delete(:name)
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

    #
    def absolute_loadpath
      loadpath.map{ |lp| File.join(location, lp) }
    end

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

    # Does this library have a matching +file+.
    #
    # file    - file path to find [to_s]
    # options - Hash of optional settings to adjust search behavior
    # options[:suffix] - automatically try standard extensions if file has none.
    # options[:legacy] - do not match within +name+ directory, eg. `lib/foo/*`.
    #
    def find(file, options={})
      legacy = options[:legacy]
      suffix = options[:suffix] || options[:suffix].nil?
      #suffix = false if options[:load]
      suffix = false if SUFFIXES.include?(File.extname(file))
      lp = loadpath
      if suffix
        SUFFIXES.each do |ext|
          lp.each do |lpath|
            unless legacy
              f = File.join(location, lpath, name, file + ext)
              if File.file?(f)
                return libfile(File.join(lpath, name), file, ext)
              end
            end
            f = File.join(location, lpath, file + ext)
            if File.file?(f)
              return libfile(lpath, file, ext)
            end
          end
        end
      else
        lp.each do |lpath|
          unless legacy
            f = File.join(location, lpath, name, file)
            if File.file?(f)
              return libfile(File.join(lpath, name), file)
            end
          end
          f = File.join(location, lpath, file)
          if File.file?(f)
            return libfile(lpath, file)
          end
        end
      end
      nil
    end

    # Alias for #find.
    alias_method :include?, :find

    # Create a new LibFile object from +lpath+, +file+ and +ext+.
    def libfile(lpath, file, ext=nil)
      LibFile.new(self, lpath, file, ext)
    end

    # Activate a library by putting it's loadpaths on the master $LOAD_PATH.
    # This is neccessary only for the fact that autoload will not utilize
    # customized require methods.
    #
    # THINK: Should we also constrain the library here? My only hesitation
    # to that is we do not have direct access the ledger object, but would
    # have to use $LEDGER.
    def activate
      # TODO: ledger constrain
      absolute_loadpath.each do |alp|
        $LOAD_PATH.unshift(alp)
      end
    end

    #
    def require(path, options={})
      if file = include?(path, options)
        file.require(options)
      else
        load_error = LoadError.new("no such file to require -- #{name}:#{path}")
        raise clean_backtrace(load_error)
      end
    end

=begin
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
=end

    #
    def load(path, options={})
      if file = include?(path, options)
        file.load(options)
      else
        load_error = LoadError.new("no such file to load -- #{name}:#{path}")
        clean_backtrace(load_error)
      end
    end

=begin
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
=end

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
      def acquire(opts={})
        if opts[:load]
          load(opts[:wrap])
        else
          require
        end
      end

      #
      def require(options={})
        return false if $".include?(localname)  # ruby 1.8 does not use absolutes
        $" << localname # ruby 1.8 does not use absolutes
        #Library.load_monitor[file] << caller if $LOAD_MONITOR
        Library.load_stack << library
        begin
          library.activate
          success = require_without_rolls(fullname)
        rescue LoadError => load_error  # TODO: deativeate this if $DEBUG ?
          raise clean_backtrace(load_error)
        ensure
          Library.load_stack.pop
        end
        success
      end

      #
      def load(options={})
        $" << localname # ruby 1.8 does not use absolutes
        #Library.load_monitor[file] << caller if $LOAD_MONITOR
        Library.load_stack << library
        begin
          library.activate
          success = load_without_rolls(fullname)
        #rescue LoadError => load_error
        #  raise clean_backtrace(load_error)
        ensure
          Library.load_stack.pop
        end
        success
      end

      def ==(other)
        fullname == other.fullname
      end

      def eql?(other)
        fullname == other.fullname
      end

      def hash
        fullname.hash
      end
    end

  end

end

