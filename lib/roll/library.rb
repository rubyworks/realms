require 'roll/config'
require 'roll/version'

require 'roll/library/metadata'
require 'roll/library/management'

#require 'roll/sign'
#require 'roll/library/kernel'

module Roll

  # = Library
  #
  class Library

    extend Management

    # Location of library in the filesystem.
    attr_reader :location

    # Name of library.
    attr_reader :name

    # Version of library. This is a Version object.
    attr_reader :version

    # Release date.
    attr_reader :date

    # Alias for date.
    alias_method :released, :date

    # Status of project.
    attr_reader :status

    # Libraries load paths.
    attr_reader :load_path


  # Paths to look for files. This is not the same as the traditional
  # $LOAD_PATH entry, which is often a directory above the libpath.
  # For example, 'lib/' may be the loadpath, but 'lib/foo/'
  # is the libpath. This is a significant difference between
  # Roll and the traditional require system.
  #
  # In general this should include all the internal load paths,
  # so long as there will be no name conflicts between directories.
  #attr_reader :libpath

  # Library dependencies. These are libraries that will be searched
  # if a file is not found in the main libpath.
  #attr_reader :depend

    # Default library file. This is the default file to load if the library
    # is required or loaded solely by it's own name. Eg. +require 'foo'+.
    # If not specified it default is then name of the library (eg. 'foo').
    attr_reader :default


    # Library dependencies. These are libraries that will be searched
    # if a file is not found in the main libpath.
    #attr_reader :requires

    # New Library.
    def initialize(metadata)
      location = metadata[:location]
      name     = metadata[:name] || metadata[:package]
      version  = metadata[:version]
      date     = metadata[:date] || metadata[:release]
      status   = metadata[:status]
      loadpath = metadata[:loadpath]

      @default  = metadata[:default] || name

      raise "no name -- #{location}"    unless name
      raise "no version -- #{location}" unless version

      @location = location
      @name     = name

      if version
        @version = (Version===version) ? version : Version.new(version)
      end

      if date
        @date = (Time===date) ? date : Time.mktime(*date.scan(/[0-9]+/))
      end

      @status  = status

      @load_path = loadpath || ['lib']
    end

    # Inspection.
    def inspect
      if version
        "#<Library #{name}/#{version}>"
      else
        "#<Library #{name}>"
      end
    end

    # Compare by version.
    def <=>(other)
      version <=> other.version
    end

    #
    def activate
      load_path.each do |lp|
        $LOAD_PATH.unshift(File.join(location, lp))
      end
    end

    # List of subdirectories that are searched when loading.
    # This defualts to ['lib/{name}', 'lib']. The first entry is
    # usually proper location; the latter is added for default 
    # compatability with the traditional require system.
    def lib
      load_path.map{ |path| File.join(location, path) }
    end

    # Does the library have any lib directories?
    def lib?
      lib.any?{ |d| File.directory?(d) }
    end

    # Location of binaries. This is alwasy bin/. This is a fixed
    # convention, unlike lib/ which needs to be more flexable.
    def bin
      File.join(location, 'bin')
    end

    # Does the library have a bin directory?
    def bin?
      File.directory?(bindir)
    end

    # Returns the path to the data directory, ie. {location}/data.
    # Note that this does not look in the system's data share (/usr/share/).
    def data #(versionless=false)
      File.join(location, 'data')
      #     if version and not versionless
      #       File.join(Config::CONFIG['datadir'], name, version)
      #     else
      #       File.join(Config::CONFIG['datadir'], name)
      #     end
    end

    # Does the library have a data directory?
    def data?
      File.directory?(datadir)
    end

    # Returns the path to the configuration directory, ie. {location}/etc.
    # Note that this does not look in the system's configuration directory (/etc/{name}).
    #
    # TODO: This in particluar probably should look in the
    #       systems config directory-- maybe an overlay effect?
    def etc
      File.join(location, 'etc')
      #     if version
      #       File.join(Config::CONFIG['confdir'], name, version)
      #     else
      #       File.join(Config::CONFIG['datadir'], name)
      #     end
    end

    # Does the library have an etc directory?
    def etc?
      File.directory?(etcdir)
    end

    # Traditional names.
    alias_method :bindir , :bin
    alias_method :datadir, :data
    alias_method :confdir, :etc


    # Library specific #require.
    #
    def require(file)
      if path = require_find(file)
        Library.load_stack << self
        begin
           success = Kernel.require(path)
        ensure
          Library.load_stack.pop
        end
        success
      #elsif lib = depend.find{ |dl| dl.require_find(file) }
      #  lib.require(file)
      else
        raise LoadError, "no such file to load -- #{name}:#{file}"
      end
    end

    # Library specific load.
    #
    def load(file, wrap=nil)
      if path = load_find(file)
        Library.load_stack << self
        begin
          success = Kernel.load(path, wrap)
        ensure
          Library.load_stack.pop
        end
        success
      else
        raise LoadError, "no such file to load -- #{name}:#{file}"
      end
    end

    # Require find.
    #
    def require_find(file)
      file = default if (file.nil? or file.empty?)
      find = File.join(location, '{' + load_path.join(',') + '}', "{#{name}/,}" + file + "{#{Library.dlext},.rb,}")
      Dir.glob(find).first
    end

    # Load find.
    #
    def load_find(file)
      file = default if (file.nil? or file.empty?)
      find = File.join(location, '{' + load_path.join(',') + '}', "{#{name}/,}" + file)
      Dir.glob(find).first
    end

    # List of subdirectories that are searched when loading.
    # This defualts to ['lib/{name}', 'lib']. The first entry is
    # usually proper location; the latter is added for default 
    # compatability with the traditional require system.
    #def libdir
    #  libpath.collect { |path| File.join(location, path) }
    #end
    #alias_method :libdirs, :libdir

    # Combines the libdirs and the libdirs of dependent libraries.
    #
    #def lib_search_path
    #  #libdirs + depend.collect{ |dl| dl.libdirs }.flatten #.uniq
    #end

    # Read metadata, if any exists. Metadata is purely extransous information.
    # The metadata will be a Reap::Metadata object if Reap is installed 
    # (providing more intelligent defaults), otherwise it  will be a  OpenStruct-like
    # object.
    #
    # TODO: Should we handle "ruby" library differently?
    #
    def metadata
      @metadata ||= Metadata.new(location)
    end

    # DEPRECATE
    alias_method :info, :metadata

    # Is metadata available?
    def metadata?
      metadata.metadata?
    end

    # If method is missing delegate to metadata, if any.
    def method_missing(s, *a, &b)
      if metadata
        metadata.send(s, *a, &b)
      else
        super
      end
    end

  end #class Library

end #module Roll

