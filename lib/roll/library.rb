#require 'rbconfig'
require 'roll/version'
require 'roll/metadata'
require 'roll/errors'

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
      @active ||= metadata.active
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

    #
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
      if suffix
        SUFFIXES.each do |ext|
          loadpath.each do |lpath|
            f = File.join(location, lpath, file + ext)
            return f if File.file?(f)
          end
        end
      else
        loadpath.each do |lpath|
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
      if suffix
        SUFFIXES.each do |ext|
          loadpath.each do |lpath|
            f = File.join(location, lpath, name, file + ext)
            return f if File.file?(f)
            f = File.join(location, lpath, file + ext)
            return f if File.file?(f)
          end
        end
      else
        loadpath.each do |lpath|
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
        success = original_require(file)
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
        success = original_load(file, wrap)
      #rescue LoadError => load_error
      #  raise clean_backtrace(load_error)
      ensure
        Library.load_stack.pop
      end
      success
    end

    # Inspection.
    def inspect
      if @version
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

    # Is there a <tt>etc/</tt> location?metadata.name
    def confdir? ; File.exist?(confdir) ; end

    # Location of library shared data directory.
    # This is always the <tt>data/</tt> directory.
    def datadir ; File.join(location, 'data') ; end

    # Is there a <tt>data/</tt> location?
    def datadir? ; File.exist?(datadir) ; end

    # Access to secondary metadata.
    def metadata
      @metadata ||= Metadata.new(location)
    end

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

  end

end

