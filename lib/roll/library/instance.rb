### = Library Class
###
### The Library class serves as an objecified location in Ruby's load paths.
###
### A library is roll-ready when it supplies a {name}-{verison}.roll file in either its
### base directory or in the base's meta/ directory. The roll file name is specifically
### designed to make library lookup fast. There is no need for Rolls to open the roll
### file until an actual version is used. It also gives the most flexability in repository
### layout. Rolls searches up to three subdirs deep looking for roll files. This is
### suitable to non-versioned libs, versioned libs, non-versioned subprojects and subprojects,
### including typical Subversion repository layouts.
class Library

  # Class instance variable @ledger stores the library references.
  #@ledger = {}

  private

    # New library. Requires location and takes identity options.
    # TODO: Version number needs to be more flexiable in handling non-numeric tuples.
    def initialize(location, rolldata=nil) #name, version, location=nil)
      @location = location
      @rolldata = rolldata

      parse_identity(rolldata)

      raise "no version -- #{location}" unless @version
      raise "no name -- #{location}" unless @name

      @default ||= "#{@name}/main" # "../#{@name}"

      @depend = []
    end

    #
    def parse_identity(data)
      name    =  data[:name]
      version  = data[:version]
      status   = data[:status]
      default  = data[:default]
      date     = data[:date]    || data[:released]

      libpath  = data[:libpath] || data[:libpaths] || []
      if libpath.empty?
        lp = data[:loadpath] || data[:loadpaths] || ['lib']

        libpath = lp + lp.map{ |path| File.join(path, name) }
        libpath = libpath.select{ |path| File.directory?(File.join(location, path)) }
      end

      @name      = name      if name
      @status    = status    if status
      @default   = default   if default

      @libpath   = libpath

      #@loadpath  = loadpath  if loadpath

      if version
        @version = (VersionNumber===version) ? version : VersionNumber.new(version)
      end

      if date
        @date = (Time===date) ? date : Time.mktime(*date.scan(/[0-9]+/))
      end
    end

  public

  # Make ready, if not already ready.

  #def ready
  #  ready! unless ready?
  #end

  # Ready the library (unconditionally).
  #
  # This will parse ROLL Runtime Configuration file.
  # The format is very simplistic for the sake of speed.
  #--
  # Can it be faster?
  #
  # Decided not to support a codename parameter as it would be optional and
  # that complicates parsing.
  #++

  #def ready!
  #  #file = @roll
  #
  #  data = File.read(file)
  #  info, *libpath = *data.split(/\s*\n\s*/)
  #  name, version, status, date, default = info.split(/\s+/)
  #
  #  version = VersionNumber.new(version)
  #  date    = Time.mktime(*date.scan(/[0-9]+/))
  #  default = default || "../#{name}"
  #
  #  #@libpath = lib.split(/[:;]/)
  #  #@depend  = dep.split(/[:;]/)
  #
  #  @version  = version
  #  @status   = status
  #  @date     = date
  #  @default  = default
  #  @libpath  = libpath
  #  #@depend
  #
  #  @ready = true
  #end


  # Is this library ready?
  #def ready? ; @ready ; end

    # Locate index file.

    #def index_file
    #  @index_file ||= (
    #    find = File.join(location, "{,meta/}*.roll")  # "{,meta/}#{name}-#{version}.roll"
    #    Dir.glob(find, File::FNM_CASEFOLD).first
    #  )
    #end

    # Retrieve any index information. This is information that
    # the library object may need to do it's job.

    #def index
    #  return if name == 'ruby'
    #  @index ||= YAML::load(File.open(index_file)) #if index_file
    #end

  # Path to library.
  attr_reader :location

  # Name of library.
  attr_reader :name

  # Version of library. This is a VersionNumber object.
  attr_reader :version

  # Release date.
  attr_reader :date

  # Status of project.
  attr_reader :status

  # Paths to look for files. This is not the same as the traditional
  # $LOAD_PATH entry, which is often a directory above the libpath.
  # For example, 'lib/' may be the loadpath, but 'lib/foo/'
  # is the libpath. This is a significant difference between
  # Roll and the traditional require system.
  #
  # In general this should include all the internal load paths,
  # so long as there will be no name conflicts between directories.
  attr_reader :libpath

  # Library dependencies. These are libraries that will be searched
  # if a file is not found in the main libpath.
  attr_reader :depend

  # Default library file. This is the default file to load if the library
  # is required or loaded solely by it's own name. Eg. @require 'foo'@.
  #
  # If not specified it defaults to @require 'foo/../foo'@.
  attr_reader :default

  # Alias for date.
  alias_method :released, :date

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

  # Traditional loadpath(s). This is usually just 'lib'.
  # NOT USED B?C MAY NOT BE SET IF ONLY LIBPATH IS USED.
  #def loadpath ; @loadpath ; end

  ###############
  # DIRECTORIES #
  ###############

  # List of subdirectories that are searched when loading.
  # This defualts to ['lib/{name}', 'lib']. The first entry is
  # usually proper location; the latter is added for default 
  # compatability with the traditional require system.
  def libdir
    libpath.collect { |path| File.join(location, path) }
  end

=begin
    #return if name == 'ruby' # NEED TO DO THIS BETTER.
    @libdir ||= (
      if @libpath
        dirs = [@libpath]
      else
        dirs = []
        loadpath.each do |path|
          if File.directory?(File.join(location, path, name))
            dirs << File.join(path,name)
          end
        end
      end
      dirs = ['lib'] if dirs.empty?
      dirs = [dirs].flatten
      dirs = dirs.collect{ |path| File.join(location, path) }
      dirs
    )
  end
=end

  alias_method :libdirs, :libdir

  # Combines the libdirs and the libdirs of dependent libraries.
  #
  # TODO: Cache this.
  def lib_search_path
    libdirs + depend.collect{ |dl| dl.libdirs }.flatten #.uniq
  end

  # Location of binaries. This is alwasy bin/ or nil if a bin directory
  # does not exist. This is a fixed convention, unlike lib/ which needs
  # to be more flexable.
  def bindir
    @bindir ||= (
      dir = File.join(location, 'bin')
      File.directory?(dir) ? dir : nil
    )
  end

  # Returns the path to the data directory, ie. {location}/data.
  # Note that this does not look in the system's data share (usr/share/).
  def datadir #(versionless=false)
    File.join(location, 'data')
    #     if version and not versionless
    #       File.join(Config::CONFIG['datadir'], name, version)
    #     else
    #       File.join(Config::CONFIG['datadir'], name)
    #     end
  end

  # Returns the path to the configuration directory, ie. {location}/etc.
  # Note that this does not look in the system's configuration directory (etc/).
  #
  # TODO: This in particluar probably should look in the
  # systems config directory-- maybe an overlay effect?
  def confdir
    File.join(location, 'etc')
    #     if version
    #       File.join(Config::CONFIG['confdir'], name, version)
    #     else
    #       File.join(Config::CONFIG['datadir'], name)
    #     end
  end

  ##################
  # REQUIRE & LOAD #
  ##################

  # Library specific #require.

  def require(file)
    if path = require_find(file)
      Library.load_stack << self #name?
      begin
         success = $LOAD_PATH.require(path) #Library.require_without_roll(path)
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

  def load(file, wrap=nil)
    if path = load_find(file)
      Library.load_stack << self #name?
      begin
        success = Library.load_without_roll(path, wrap)
      ensure
        Library.load_stack.pop
      end
      success
    else
      raise LoadError, "no such file to load -- #{name}:#{file}"
    end
  end

  # Require find.

  def require_find(file)
    file = default if (file.nil? or file.empty?)
    find = File.join('{' + lib_search_path.join(',') + '}', file + "{#{Library.dlext},.rb,}")
    Dir.glob(find).first
  end

  # Load find.

  def load_find(file)
    file = default if (file.nil? or file.empty?)
    find = File.join('{' + libdirs.join(',') + '}', file)
    Dir.glob(find).first
  end

  # Put the lib's load paths into the local lookup of the current library or
  # if at the toplevel, in the standard lookup.
  #--
  # TODO Maybe call this 'import' instead?
  #++

  def utilize
    lastlib = Library.load_stack.last
    if lastlib
      lastlib.depend << self
      #libdirs.each do |path|
      #  lastlib.append_to_libpath(path)
      #end
    else
# TODO
      #libdirs.each do |path|
      #  Library.load_path.unshift(path)
      #end
      #Library.load_path.uniq!
    end
    self
  end

  ####################
  # LIBRARY METADATA #
  ####################

  PROJECT_FILE = '{meta/,}project{,info}{,.yaml,.yml}'

  # Read metadata, if any exists. Metadata is purely extransous information.
  # Therefore it is kept in a seaprate 'project' file, and only loaded
  # if requested. The metadata will be a Reap::Project object if Reap
  # is installed (providing more intelligent project info), otherwise it
  # will be a simple OpenStruct object.
  #
  # If no metadata is found, return false. If library is ruby's core/standard
  # then, of course, no metadata exits and it also return false.
  #
  # TODO: Should we handle special ruby library differently?

  def metadata
    return @metadata unless @metadata.nil?
    @metadata = (
      if defined?(::Reap)
        ::Reap::Project.load(location) #
      else
        Kernel.require 'ostruct'
        file = Dir.glob(File.join(location,PROJECT_FILE), File::FNM_CASEFOLD).first
        if file
          require 'yaml'
          data = YAML::load(File.open(file))
          OpenStruct.new(data)
        else
          false
        end
      end
    )
  end

  alias_method :info, :metadata

  # If method is missing delegate to metadata, if any.

  def method_missing(s, *a, &b)
    if metadata
      metadata.send(s, *a, &b)
    else
      super
    end
  end

  # Is metadata available?

  def metadata?
    metadata ? true : false
  end


  # TODO Does this library have a remote source?
  #def remote?
  #  metadata? and source and pubkey
  #end
  

  #  def reload_project
  #    #return @projectinfo unless @projectinfo.nil?
  #
  #    #return @projectinfo = {} if name == 'ruby'
  #
  #    #find = File.join(location, '{meta/,}{project}{.yaml,.yml,}')
  #    #file = Dir.glob(find, File::FNM_CASEFOLD).first
  #
  #    return @metadata = {} unless file
  #
  #    @metadata = (
  #      data = YAML::load(File.new(file))
  #      data = data.inject({}){ |h, (k,v)| h[k.to_s.downcase] = v ; h }
  #      data['file']    = file
  #      data['name']    = name
  #      data['version'] = version.to_s
  #      data
  #    )
  #  end

    #def project_file
    #  return @file unless @file.nil?
    #  @file = (
    #    file = Dir.glob(File.join(location,'{,meta/}project{.yaml,.yml,}'), File::FNM_CASEFOLD)[0]
    #    File.file?(file) ? file : false
    #  )
    #end

end

