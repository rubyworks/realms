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

      @default ||= "#{@name}" # "../#{@name}"

      @depend = []
    end

    #
    def parse_identity(data)
      name     = data[:name]    || data[:project]
      version  = data[:version]
      status   = data[:status]
      default  = data[:default]
      date     = data[:date]    || data[:released]
      libpath  = data[:libpath] || data[:libpaths] || []

      if libpath.empty?
        lp = data[:loadpath] || data[:loadpaths] || ['lib']

        libpath = lp
        libpath = libpath + lp.map{ |path| File.join(path, name) } if name
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




  # Traditional loadpath(s). This is usually just 'lib'.
  # NOT USED B?C MAY NOT BE SET IF ONLY LIBPATH IS USED.
  #def loadpath ; @loadpath ; end


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

  # Put the lib's load paths into the local lookup of the current library or
  # if at the toplevel, in the standard lookup.
  #--
  # NOTE: I DON'T THINK THIS IS A GOOD IDEA.
  #++
  #def utilize
  #  lastlib = Library.load_stack.last
  #  if lastlib
  #    lastlib.depend << self
  #    #libdirs.each do |path|
  #    #  lastlib.append_to_libpath(path)
  #    #end
  #  else
  #    #libdirs.each do |path|
  #    #  Library.load_path.unshift(path)
  #    #end
  #    #Library.load_path.uniq!
  #  end
  #  self
  #end

end

