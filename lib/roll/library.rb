require 'yaml'

require 'roll/config'
require 'roll/version'

#require 'roll/library/metadata'
require 'roll/library/management'

#require 'roll/sign'
#require 'roll/library/kernel'

module Roll

  class MissingReqMetadata < NameError
  end

  # = Library
  #
  class Library

    extend Management

    # Location of library in the filesystem.
    attr_reader :location

    # Name of the library.
    attr :name

    # Version of library.
    attr :version

    # Release date.
    attr :released

    # Paths within the library to put of the $LOAD_PATH.
    attr :loadpath

    # Alias for released.
    alias_method :date, :released

    # Alias for loadpath.
    alias_method :load_path, :loadpath

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

    # Library dependencies. These are libraries that will be searched
    # if a file is not found in the main libpath.
    #attr_reader :requires

    # New Library.
    def initialize(location)
      @location = location
      @metadata = {}

      @name     = read_metadata('name')
      @version  = read_metadata('version')
      @active   = read_metadata('active')

      # TODO: improve active marker support
      raise MissingReqMetadata, "[ROLL] IGNORE library: #{location}" if @active == 'false'

      raise MissingReqMetadata, "[ROLL] OMIT lacking name: #{location}" unless name
      raise MissingReqMetadata, "[ROLL] OMIT lacking version: #{location}" unless version

      begin
        @released = (
          if rel = read_metadata('released')
            (Time===rel) ? rel : Time.mktime(*rel.scan(/[0-9]+/))
          end
        )
      rescue
      end

      @loadpath = read_metadata('loadpath', :yaml=>true, :list=>true)
      @loadpath = @loadpath || ['lib']
    end

    # Default library file. This is the file to load when
    # using +aquire+ and the request file is solely the
    # library name. Eg. +acquire 'foo'+. It is always the 
    # library name (eg. 'foo').
    def default
      name
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

    # Activate this version of the library, placing it's load paths
    # in the $LOAD_PATH, and making it the only version available
    # in the ledger.
    def activate
      Library.ledger[name] = self
      load_path.each do |lp|
        $LOAD_PATH.unshift(File.join(location, lp))
      end
      self # returns self
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
    def metadata(name)
      if @metadata.key?(name)
        @metadata[name]
      else
        @metadata[name] = read_metadata(name)
      end
    end

    #
    def read_metadata(name, opts={})
      file = Dir[File.join(location, '{meta,.meta}', name)].first
      if file && File.file?(file)
        if opts[:yaml]
          data = YAML.load(File.new(file))
        else
          data = File.read(file).strip
        end
        #$stderr << "#{self.inspect} #{name}: #{data.class} #{data} | #{opts.inspect}\n"
        if String===data && opts[:list]
          data = data.strip.split(/\s+/)  # TODO: use Shellwords so filenames can have spaces?
        else
          data
        end
      else
        data = nil
      end
      data
    end

    # If method is missing delegate to metadata, if any.
    def method_missing(s, *a, &b)
      $stderr << "method_missing: #{s.inspect}\n" if ENV['ROLL_DEBUG']
      s = s.to_s
      super if /\?$/ =~ s
      super if /\!$/ =~ s
      super if /\=$/ =~ s
      if val = metadata(s)
        val
      else
        super
      end
    end

      # Parse version stamp into it's various parts.
      #def parse_version_stamp(text)
      #  #info, *libpath = *data.split(/\s*\n\s*/)
      #  name, version, status, date = *text.split(/\s+/)
      #  version = Version.new(version)
      #  date    = Time.mktime(*date.scan(/[0-9]+/))
      #  #default = default || "../#{name}"
      #  return {:name => name, :version => version, :status => status, :date => date}
      #end

  end #class Library

end #module Roll

