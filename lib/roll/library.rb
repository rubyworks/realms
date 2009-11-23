require 'rbconfig'

module Roll
  require 'roll/manageable'
  require 'roll/version'
  require 'roll/metadata'
  require 'roll/errors'

  class Library

    # Dynamic link extension.
    DLEXT = '.' + ::Config::CONFIG['DLEXT']

    #
    extend Manageable

    # NOTE: Not used yet.
    def self.load_monitor
      @load_monitor ||= Hash.new{|h,k| h[k]=[] }
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
      @name ||= load_name
    end

    #
    def version
      @version ||= load_version
    end

    #
    def active
      @active ||= load_active
    end

    #
    def loadpath
      @loadpath ||= load_loadpath
    end

    #
    def released
      @released ||= load_released
    end

    # Does this library have this library +file+?
    #--
    # TODO: Rename to #find (?)
    #++
    def include?(file)
      case File.extname(file)
      when '.rb', DLEXT
        find = File.join(lookup_glob, file)
      else
        find = File.join(lookup_glob, "{#{name}/,}" + file + '{' + ".rb,#{DLEXT}" + '}')
      end
      Dir[find].first
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
        success = Kernel.require(file)
      rescue => load_error
        raise clean_backtrace(load_error)
      ensure
        Library.load_stack.pop
      end
      success
    end

    #
    def load(file, wrap=nil)
      if path = include?(file)
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
        success = Kernel.load(file, wrap)
      rescue => load_error
        raise clean_backtrace(load_error)
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
#
#    # Location of executable. This is alwasy bin/. This is a fixed
#    # convention, unlike lib/ which needs to be more flexable.
#
#    def bindir  ; File.join(location, 'bin') ; end
#    def bindir? ; File.exist?(bin) ; end

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

    # Access to secondary metadata.
    def metadata
      @metadata ||= Metadata.new(location)
    end

  private

    # Get library name.
    def load_name
      file = Dir[File.join(location, '{,.}meta', 'name')].first
      if file
        File.read(file).strip
      end
    end

    # Get library version.
    # TODO: handle VERSION file
    # TODO: handle YAML
    def load_version
      file = Dir[File.join(location, '{,.}meta', 'version')].first
      if file
        Version.new(File.read(file).strip)
      end
    end

    # Get library active state.
    def load_active
      file = Dir[File.join(location, '{,.}meta', 'active')].first
      if file
        File.read(file).strip != 'false'
      else
        true
      end
    end

    # Get library loadpath.
    def load_loadpath
      file = Dir[File.join(location, '{,.}meta', 'loadpath')].first
      if file
        val = File.read(file).strip.split(/\s*\n/)  # TODO: handle YAML
        val = ['lib'] if val.empty?
        val
      else
        ['lib']
      end
    end

    # Get library release date.
    def load_released
      file = Dir[File.join(location, '{,.}meta', 'released')].first
      if file
        File.read(file).strip
      else
        "1900-01-01"  # TODO: default to what?
      end
    end

    #
    def lookup_glob
      File.join(location, '{'+loadpath.join(',')+'}')
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

  end

end

