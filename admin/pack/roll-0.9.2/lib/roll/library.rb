# TITLE:
#
#   library.rb
#
# LICENSE:
#
#   Copyright (c) 2007 Thomas Sawyer, Ruby License
#
# TODO:
#
#   - Maybe add autopackage install system? If compresses pacakges are found in
#     a certain directory they are automatically installed?
#
#   - What about remotes? What about version tiers when remote requiring?
#
#   - Library #use should be local to the give library. This way other libraries
#     can use what they want without adding to the global require space.
#     And hopefully this help elmininate the need to rescue for backward compatability.
#
# NOTE:
#
#   - Roll's require/load doesn't work if called from within Kernel module!!!

require 'yaml'
require 'rbconfig'
#require 'fileutils'

require 'roll/version'
require 'roll/require'  # TODO: incorporate into this file.
#require 'roll/sign'

# We need to hold a copy of the original $LOAD_PATH
# for specified "ruby: ..." loads.

$RUBY_PATH = $LOAD_PATH.dup

# Locations of rolls-ready libraries.

rolldir = 'ruby_site'
sitedir = ::Config::CONFIG['sitedir']
version = ::Config::CONFIG['ruby_version']
default = File.join(File.dirname(sitedir), rolldir, version)

$LOAD_SITE = [default] + ENV['ROLL_PATH'].to_s.split(/[:;]/)  # TODO add '.' ?

# = Library Class
#
# The Library class serves as an objecified location in Ruby's load paths.
#
# The Library qua class also serves as the library manager, storing a ledger of
# available libraries.
#
# A library is roll-ready when it supplies a {name}-{verison}.roll file in either its
# base directory or in the base's meta/ directory. The roll file name is specifically
# designed to make library lookup fast. There is no need for Rolls to open the roll
# file until an actual version is used. It also gives the most flexability in repository
# layout. Rolls searches up to three subdirs deep looking for roll files. This is
# suitable to non-versioned libs, versioned libs, non-versioned subprojects and subprojects,
# including typical Subversion repository layouts.

class Library

  # VersionError is raised when a requested version cannot be found.

  class VersionError < ::RangeError  # :nodoc:
  end

  # VersionConflict is raised when selecting another version
  # of a library when a previous version has already been selected.

  class VersionConflict < ::LoadError  # :nodoc:
  end

  # Class instance variable @ledger stores the library references.

  #@ledger = {}

  #

  class << self

    #def ledger ; @ledger; end

    def cache_file
      @cache_file ||= File.join(Config::CONFIG['localstatedir'], 'cache', 'roll', 'cache.yaml')
    end

    # load cache

    def ledger
      @ledger ||= YAML::load(File.read(cache_file))
    end

    # Scan the site locations for libraries.

    def scan
      @ledger = {}

      # First we add Ruby's core and standard libraries.
      @ledger['ruby'] = Library.new( Library.rubylibdir,
                                     :name=>'ruby',
                                     :version=>RUBY_VERSION,
                                     :load_path=>Library.ruby_path )

      #scan_working() if $DEBUG

      sites = '{' + $LOAD_SITE.join(',') + '}'
      rolls = Dir.glob(sites + '/*{,/*,/*/*}{,/meta}/project.yaml', File::FNM_CASEFOLD)

      rolls.uniq!

      rolls.each do |roll|
        location = File.dirname(roll)
        location = File.dirname(location) if File.basename(location).downcase == 'meta'

        begin
          metadata = load_project_file(roll)
          versdata = load_version_stamp(location)
          metadata.update(versdata)

          metadata[:name] ||= metadata[:project] || metadata[:title].downcase

          #next if metadata['roll'] == false

          lib = Library.new(location, metadata) #, roll)

          name = lib.name.downcase

          @ledger[name] ||= []
          @ledger[name] << lib
        rescue
          warn "scan error, library omitted -- #{roll}"
        end
      end
    end

    # Load project file.

    def load_project_file(file)
      YAML::load(File.open(file)).inject({}) do |data, (k,v)|
        data[k.to_s.downcase.to_sym] = v; data
      end
    end

    # Load and parse version stamp file.

    def load_version_stamp(location)
      file = Dir.glob(File.join(location,'{,meta/}VERSION'), File::FNM_CASEFOLD)[0]
      if file
        data = File.read(file)
        parse_version_stamp(data)
      else
        {}
      end
    end

    #

    def parse_version_stamp(data)
      info, *libpath = *data.split(/\s*\n\s*/)
      version, status, date, default = info.split(/\s+/)

      version = VersionNumber.new(version)
      date    = Time.mktime(*date.scan(/[0-9]+/))
      default = default || "../#{name}"

      return { :version => version, :status => status, :date => date }
    end

#     def parse_rollfile
#       data = File.read(file)
#       info, *libpath = *data.split(/\s*\n\s*/)
#       name, version, status, date, default = info.split(/\s+/)
#
#       version = VersionNumber.new(version)
#       date    = Time.mktime(*date.scan(/[0-9]+/))
#       default = default || "../#{name}"
#
#       return name, version. status, date, default, libpath
#     end

    #     #if versions.empty?
    #     #  @ledger[name] ||= Library.new(dir, :name=>name, :version=>'0') #Version.new('0', dir)

    #     # Scan current working location to see if there's
    #     # a library. This will ascend from the current
    #     # working directy to one level below root looking
    #     # for a lib/ directory.
    #     #--
    #     # TODO CHANGE TO LOOK FOR INDEX FILE.
    #     #++
    #     def scan_working
    #       paths = Dir.pwd.split('/')
    #       (paths.size-1).downto(1) do |n|
    #         dir = File.join( *(paths.slice(0..n) << 'lib') )
    #         if File.directory? dir
    #           $LOAD_SITE.unshift dir
    #         end
    #       end
    #     end

    # Return a list of library names.

    def list
      ledger.keys
    end

    # Libraries are Singleton pattern.

    def instance(name, constraint=nil)
      name = name.to_s

      #raise "no library -- #{name}" unless ledger.include?( name )
      return nil unless ledger.include?(name)

      library = ledger[name]

      if Library===library
        if constraint
          raise VersionConflict, "previously selected version -- #{ledger[name].version}"
        else
          library
        end
      else # library is an array of versions
        library.each{|lib| lib.ready }  # prepare the versions, if needed
        if constraint
          compare = VersionNumber.constrant_lambda(constraint)
          version = library.select(&compare).max
        else
          version = library.max
        end
        unless version
          raise VersionError, "no library version -- #{name} #{constraint}"
        end
        ledger[name] = version
      end
    end

    # A shortcut for #instance.
    alias_method :[], :instance

    # Same as #instance but will raise and error if the library is not found.

    def open(name, constraint=nil, &yld)
      lib = instance(name, constraint)
      unless lib
        raise LoadError, "no library -- #{name}"
      end
      yield(lib) if yld
      lib
    end

    # Dynamic link extension.

    def dlext
      @dlext ||= '.' + ::Config::CONFIG['DLEXT']
    end

    # Location of rolls-ready libs.

    def load_site ; $LOAD_SITE ; end

    # Standard load path. This is where all "used" libs
    # a located.

    def load_path ; $LOAD_PATH ; end

    # Location of Ruby's core/standard libraries.

    def ruby_path ; $RUBY_PATH ; end

    # The main ruby lib dir (usually /usr/lib/ruby).

    def rubylibdir
      ::Config::CONFIG['rubylibdir']
    end

    #

    def load_stack
      @load_stack ||= []
    end

    # Rolls requires a modification to #require and #load.
    # So that it is not neccessary to make the library() call
    # if you just want the latest version.
    #
    # This would be a bit simpler if we mandated the
    # use of the ':' notation when specifying the library
    # name. Use of the ':' is robust. But we cannot do this
    # w/o loosing backward-compatability. Using '/' in its
    # place has the potential for pathname clashing, albeit
    # the likelihood is small. There are two ways to bypass
    # the problem if it arises. Use 'ruby:{path}' if the
    # conflicting lib is a ruby core or standard library.
    # Use ':{path}' to bypass Roll system altogether.
    #
    # FIXME This doesn;t work for autoload. This is really
    # a bug in Ruby b/c autoload is not using the overriden
    # require.

    alias_method :require_without_roll, :require

    # Require script.

    def require(file)
      lib, path, must = *parse_load_parameters(file)
      return lib.require(path) if must

      begin
        require_without_roll(file)
      rescue LoadError => e
        if lib
          return lib.require(path)
        else
          raise e
        end
      end
      #/--(.*?)$/ =~ e.to_s.strip
      #real_file = $1.strip
      #if real_file != file
    end

    alias_method :load_without_roll, :load

    # Require script.

    def load(file, wrap=false)
      lib, path, must = *parse_load_parameters(file)
      return lib.load(path, wrap) if must

      begin
        load_without_roll(file, wrap)
      rescue LoadError => e
        if lib
          return lib.load(path, wrap)
        else
          raise e
        end
      end
    end

    #

    def module_require(mod, file)
      lib, path, must = *parse_load_parameters(file)
      return lib.module_require(mod, path) if must

      begin
        mod.module_require_without_roll(file)
      rescue LoadError => e
        if lib
          return lib.module_require(mod, path)
        else
          raise e
        end
      end
    end

    #

    def module_load(mod, file, wrap=false)
      lib, path, must = *parse_load_parameters(file)
      return lib.module_load(mod, path, wrap) if must

      begin
        mod.module_load_without_roll(file, wrap)
      rescue LoadError => e
        if lib
          return lib.module_load(mod, path, wrap)
        else
          raise e
        end
      end
    end

#   #
#   def autoload(base, file)
#     if file.index(':')
#       name, file = file.split(':')
#       if name == ''
#         Kernel.autoload(base, file)
#       elsif lib = Library.instance(name)
#         lib.autoload(base, file)
#       else
#         raise LoadError, "no library found -- #{name}"
#       end
#     else
#       name, *rest = file.split('/')
#       if lib = Library.instance(name)
#         lib.autoload(base, File.join(*rest))
#       else
#         Kernel.autoload(base, file)
#       end
#     end
#   end

  private

    def parse_load_parameters(file)
      if must = file.index(':')
        name, path = file.split(':')
      else
        name, *rest = file.split('/')
        path = File.join(*rest)
      end
      name = nil if name == ''
      lib = name ? Library.instance(name) : nil
      raise LoadError, "no library found -- #{file}" if must && !lib
      return lib, path, must
    end

  end # class << self


  private

    # New library. Requires location and takes identity options.
    # TODO: Version number needs to be more flexiable in handling non-numeric tuples.

    def initialize(location, metadata=nil) #name, version, location=nil)
      @location = location
      @metadata = metadata

      ready_identity(metadata)

      @default ||= "#{@name}/main" # "../#{@name}"

      raise "no name -- #{location}" unless @name
    end

    #

    def file
      return @file unless @file.nil?
      @file = (
        file = Dir.glob(File.join(location,'{,meta/}project{.yaml,.yml,}'), File::FNM_CASEFOLD)[0]
        File.file?(file) ? file : false
      )
    end

    #

    def ready_identity(data)
      parse_identity(data)

      raise "no version -- #{location}" unless @version

      @ready = true
    end

    #

    def parse_identity(data)
      name    = data[:name]
      version = data[:version]
      status  = data[:status]
      date    = data[:date] || data[:released]
      default = data[:default]
      libpath = data[:libpath] || data[:libpaths] || data[:loadpath] || data[:loadpaths]

      @name      = name      if name
      @status    = status    if status
      @default   = default   if default
      @libpath   = libpath   if libpath

      if version
        @version = (VersionNumber===version) ? version : VersionNumber.new(version)
      end

      if date
        @date = (Time===date) ? date : Time.mktime(*date.scan(/[0-9]+/))
      end
    end

    # Identify a library based on it's location.

    def identify(location)
      file = File.join(location,'{,meta/}*.roll')
      Dir.glob(file, File::FNM_CASEFOLD).first
    end

  public

  # Make ready, if not already ready.

  def ready
    ready! unless ready?
  end

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

  def ready!
    #file = @roll

    data = File.read(file)
    info, *libpath = *data.split(/\s*\n\s*/)
    name, version, status, date, default = info.split(/\s+/)

    version = VersionNumber.new(version)
    date    = Time.mktime(*date.scan(/[0-9]+/))
    default = default || "../#{name}"

    #@libpath = lib.split(/[:;]/)
    #@depend  = dep.split(/[:;]/)

    @version  = version
    @status   = status
    @date     = date
    @default  = default
    @libpath  = libpath
    #@depend

    @ready = true
  end


  # Is this library ready?

  def ready? ; @ready ; end

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

  # Paths to look for files.

  attr_reader :libpath

  # Dependencies.
  #attr_reader :depend

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

  # Read metadata, if any exists. Metadata is purely extransous information.
  # Therefore it is kept in a seaprate 'package' file, and only loaded
  # if requested. The metadata will be a Box::Package object if Box
  # is installed (providing more intelligent package info), otherwise it
  # will be a simple Struct object.
  #
  # If no metadata is found, return false. If library is ruby's core/standard
  # then, of course, no metadata exits and it also return false.
  #
  # TODO: Should we handle special ruby library differently?

  #

  def metadata
    @projectinfo ||= (
      if defined?(::Box)
        ::Box::Package.new(@metadata) #
      else
        Kernel.require 'ostruct'
        OpenStruct.new(@metadata)
      end
    )
  end

  #

  def reload_project
    #return @projectinfo unless @projectinfo.nil?

    #return @projectinfo = {} if name == 'ruby'

    #find = File.join(location, '{meta/,}{project}{.yaml,.yml,}')
    #file = Dir.glob(find, File::FNM_CASEFOLD).first

    return @metadata = {} unless file

    @metadata = (
      data = YAML::load(File.new(file))
      data = data.inject({}){ |h, (k,v)| h[k.to_s.downcase] = v ; h }
      data['file']    = file
      data['name']    = name
      data['version'] = version.to_s
      data
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

  # Compare by version.

  def <=>(other)
    version <=> other.version
  end

  # List of subdirectories that are searched when loading libs.
  # In general this should include all the libs internal load paths,
  # so long as there will be no name conflicts between directories.

  def libdir
    return if name == 'ruby' # NEED TO DO THIS BETTER.
    @libdir ||= (
      dirs = @libpath || 'lib'
      dirs = [dirs].flatten
      dirs = dirs.collect{ |path| File.join(location, path) }
      dirs
    )
  end
  alias_method :libdirs,    :libdir
  alias_method :load_path,  :libdir
  alias_method :load_paths, :libdir

  # Location of binaries. This is alwasy bin/ or nil if a bin directory
  # does not exist. This is a fixed convention, unlike lib/ which needs
  # to be more flexable.

  def bindir
    @bindir ||= (
      dir = File.join(location, 'bin')
      File.directory?(dir) ? dir : nil
    )
  end

#     return @bin_path if @bin_path
#     return [] if name == "ruby" # TODO NEED TO DO THIS BETTER?
#     if metadata.bin_path
#       @bin_path = metadata.bin_path.collect{ |path| File.join(location, path) }
#     else
#       if File.directory?(File.join(location, 'bin'))
#         @bin_path = [File.join(location, 'bin')]
#       else
#         @bin_path = []
#       end
#     end
#     return @bin_path

  # Return the path to the data directory.
  #
  # TODO: Look in system share?

  def datadir #(versionless=false)
    File.join(location, 'data')
    #     if version and not versionless
    #       File.join(Config::CONFIG['datadir'], name, version)
    #     else
    #       File.join(Config::CONFIG['datadir'], name)
    #     end
  end

  # Return the path to the configuration directory.
  #--
  #  TODO: Can configuration directories be versioned?
  #++
  def confdir
    File.join(location, 'conf')
    #     if version
    #       File.join(Config::CONFIG['confdir'], name, version)
    #     else
    #       File.join(Config::CONFIG['datadir'], name)
    #     end
  end

  # Require find.

  def require_find(file)
    file = default if (file.nil? or file.empty?)
    glob = File.join('{' + load_path.join(',') + '}', file + "{#{Library.dlext},.rb,}")
    Dir.glob(glob).first
  end

  # Load find.

  def load_find(file)
    file = default if (file.nil? or file.empty?)
    glob = File.join('{' + load_path.join(',') + '}', file)
    Dir.glob(glob).first
  end

  # Library specific #require.

  def require(file)
    if path = require_find(file)
      Library.load_stack << self #name?
      success = Kernel.require(path)
      Library.load_stack.pop
      success
    else
      raise LoadError, "no such file to load -- #{name}:#{file}"
    end
  end

  # Library specific load.

  def load(file, wrap=nil)
    if path = load_find(file)
      Library.load_stack << self #name?
      success = Kernel.load(path, wrap)
      Library.load_stack.pop
      success
    else
      raise LoadError, "no such file to load -- #{name}:#{file}"
    end
  end

#   # Library specific autoload.
#
#   def autoload(base, file)
#     if path = require_find(file)
#       Kernel.autoload(base, file)
#     else
#       raise LoadError, "no such file to autoload -- #{name}:#{file}"
#     end
#   end

  # Require into module.

  def module_require(mod, file)
    if path = require_find(file)
      mod.module_require_without_roll(path)  # FIXME
    else
      raise LoadError, "no such file to load -- #{name}:#{file}"
    end
  end

  # Load into module.

  def module_load(mod, file)
    if path = load_find(file)
      mod.module_load_without_roll(path)  # FIXME
    else
      raise LoadError, "no such file to load -- #{name}:#{file}"
    end
  end

#   # Library specific autoload for module.
#
#   def module_autoload(mod, base, file)
#     if path = require_find(file)
#       mod.autoload_without_roll(base, file)
#     else
#       raise LoadError, "no such file to autoload -- #{name}:#{file}"
#     end
#   end

  # Put the lib's load paths into the standard lookup.
  #--
  # TODO Maybe call 'import' instead?
  #++

  def utilize
    libdirs.each do |path|
      Library.load_path.unshift(path)
    end
    Library.load_path.uniq!
    self
  end

  #

  #def to_yaml
  #end

end


module ::Config

  # Return the path to the data directory associated with the given
  # library name.
  #--
  #Normally this is just
  # "#{Config::CONFIG['datadir']}/#{name}", but may be
  # modified by packages like RubyGems and Rolls to handle
  # versioned data directories.
  #++

  def self.datadir(name, versionless=false)
    if lib = Library.instance(name)
      lib.datadir(versionless)
    else
      File.join(CONFIG['datadir'], name)
    end
  end

  # Return the path to the configuration directory.

  def self.confdir(name)
    if lib = Library.instance(name)
      lib.confdir
    else
      File.join(CONFIG['datadir'], name)
    end
  end
end


module ::Kernel

  # In which library is this file participating?

  def __LIBRARY__
    Library.load_stack.last
  end

  # Activate a library.

  def library(name, constraint=nil)
    Library.open(name, constraint)
  end
  module_function :library

  # Use library. This activates a library, and adds
  # it's load_path to the global $LOAD_PATH.
  #--
  # Maybe call this #import instead ?
  #++

  def use(name, constraint=nil)
    Library.open(name, constraint).utilize
  end

  # Require script.

  def require(file)
    Library.require(file)
  end

  # Load script.

  def load(file, wrap=false)
    Library.load(file, wrap)
  end

end


class ::Module

  alias_method :module_require_without_roll, :module_require

  # Module require script.

  def module_require(file)
    Library.module_require(self, file)
  end

  alias_method :module_load_without_roll, :module_load

  # Module load script.

  def module_load(file, wrap=false)
    Library.module_load(self, file, wrap)
  end

end


# Prime the library ledger.
#Library.scan
#Library.load_cache

# TODO: With Box available, we can have rich package metadata.
#begin ; require 'box:package' ; rescue LoadError ; end
