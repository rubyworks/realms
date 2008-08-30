# TITLE:
#
#   Library
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

require 'roll/version'
#require 'roll/sign'

# We need to hold a copy of the original $LOAD_PATH
# for specified "ruby: ..." loads.

$RUBY_PATH = $LOAD_PATH.dup

# Roll configuration.

#sysdir  = Config::CONFIG['sysconfdir']
#sysfile = File.join(sysdir, 'roll.yaml')
#if File.exist?(sysfile)
#  ROLL_CONFIG = YAML.load(File.new(sysfile))
#else
#  ROLL_CONFIG = { 'path' => [] }
#end

# FIXME: when using sudo roll. maybe put back in etc/roll/ ?
#        and use .etc/roll/ for per-user rolls.
ROLL_PATH = ENV['ROLL_PATH']

# Locations of roll-ready libraries.

rolldir = 'ruby_site'
sitedir = Config::CONFIG['sitedir']
version = Config::CONFIG['ruby_version']
default = File.join(File.dirname(sitedir), rolldir, version)

$LOAD_SITE = [default] #+ ENV['ROLL_PATH'].to_s.split(/[:;]/)  # TODO add '.' ?
$LOAD_SITE.concat(ROLL_PATH.to_s.split(/[:;]/))  # TODO add '.' ?

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

  # TODO: Use Common too.
  COMMON_CACHE_FILE = File.join(Config::CONFIG['sysconfdir'], 'roll', 'ledger.list')

  CACHE_FILE = File.join(ENV['HOME'], '.etc', 'roll', 'ledger.list')

  DEPTH = 4

  #

  class << self

    attr :ledger
    attr :locations

    # Setup Library system.

    def setup(live=false)
      @ledger    = {}
      @locations = []

      # First we add Ruby's core and standard libraries to the ledger.
      @ledger['ruby'] = Library.new( Library.rubylibdir,
                                     :name=>'ruby',
                                     :version=>RUBY_VERSION,
                                     :libpath=>Library.ruby_path )

      if ENV['ROLL_LIVE'] or live
        locations = live_load
      else
        locations = (File.exist?(CACHE_FILE) ? File.read(CACHE_FILE).split("\n") : [])
      end

      load_projects(*locations)
    end

    def live_load
      find(DEPTH, *$LOAD_SITE)
    end

    def find(depth, *paths)
      return [] if depth == 0
      loc = []
      while path = paths.shift
        next unless File.directory?(path)
        d = Dir.new(path)
        begin
          while f = d.read
            if f == '.roll'
              loc << path
              break
            elsif f[0] == ?.
              next
            elsif File.directory?(abs = File.join(path,f))
              loc.concat(find(depth-1, abs))
            end
          end
        ensure
          d.close
        end
      end
      loc
    end

    #

    def load_projects(*locations)
      locations.each do |location|
        begin
          metadata = load_rollfile(location)
          #versdata = load_version(location)
          #metadata.update(versdata)

          metadata[:name] ||= metadata[:project] || metadata[:title].downcase

          next if metadata[:deactive]  # possible to deactivate a rolled project

          lib = Library.new(location, metadata)

          name = lib.name.downcase

          @ledger[name] ||= []
          @ledger[name] << lib

          @locations << location
        rescue => e
          raise e if ENV['ROLL_DEBUG'] or $DEBUG
          warn "scan error, library omitted -- #{location}" if ENV['ROLL_WARN']
        end
      end
    end

    # Load roll file. A roll file (.roll) is a simply
    # key = value formatted file. The assignment
    # divider can be either an '=' or a ':'. YAML was not
    # used here becuase Ruby does not load YAML by default
    # and I wanted to honor that --though I secretly think
    # it would be cool if YAML were integrated. Becuase YAML
    # is not being used, the libpath and loadpath parameter
    # are simply /[:;,]/-separated strings.

    def load_rollfile(location)
      data = {}
      rollfile = File.join(location, '.roll')
      content = File.read(rollfile)
      entries = content.split("\n")
      entries.each do |entry|
        next if /^#/.match(entry)  # skip comment lines
        i = entry.index('=') || entry.index(':')
        key, value = entry[0...i], entry[i+1..-1]
        data[key.strip.downcase.to_sym] = value.strip
      end
      data[:libpath]  = data[:libpath].split(/[:;,]/)   if data[:libpath]
      data[:loadpath] = data[:loadpath].split(/[:;,]/) if data[:loadpath]
      data
    end

=begin
    # Load and parse version stamp file.

    def load_version(location)
      file = Dir.glob(File.join(location,'{,meta/}VERSION'), File::FNM_CASEFOLD).first
      if file
        data = YAML::load(File.new(file))
        #parse_version_stamp(data)
      else
        data = {}
      end
      case data
      when String
        parse_version_stamp(data)
      else
         data
      end
    end
=end

    #

    def parse_version_stamp(data)
      info, *libpath = *data.split(/\s*\n\s*/)
      version, status, date, default = info.split(/\s+/)

      version = VersionNumber.new(version)
      date    = Time.mktime(*date.scan(/[0-9]+/))
      default = default || "../#{name}"

      return { :version => version, :status => status, :date => date }
    end

    # Update cache.

    def update_cache
      setup(true) # live setup
      FileUtils.mkdir_p(File.dirname(CACHE_FILE))
      File.open(CACHE_FILE, 'w') do |f|
        f << locations.join("\n")
      end
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
        #library.each{|lib| lib.ready }  # prepare the versions, if needed
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
    # place has a slight potential for pathname clashing, albeit
    # the likelihood is small. There are two ways to bypass
    # the problem if it arises. Use 'ruby:{path}' if the
    # conflicting lib is a ruby core or standard library.
    # Use ':{path}' to bypass Roll system altogether.
    #
    # FIXME This doesn;t work for autoload. This is really
    # a bug in Ruby b/c autoload is not using the overriden
    # require.

    alias_method :require_without_roll, :require

    public :require_without_roll

    # Require script.
    #
    # NOTE: Ideally this would first look for a specific library 
    #       via ':', and then try the current library. Failing
    #       that it would fall back to Ruby itself. However this
    #       would break compatibility.
    #
    def require(file)
      # specific library
      if file.index(':')
        name, path = file.split(':')
        lib = Library.instance(name)
        raise LoadError, "no library found -- #{file}" unless lib
        return lib.require(path)
      end

      # potential specified library, ie. head of path is library name
      name, *rest = file.split('/')
      path = File.join(*rest)
      path = nil if path.empty?
      if lib = Library.instance(name)
        begin
          return lib.require(path)
        rescue LoadError => load_error
          raise load_error if ENV['ROLL_DEBUG']
        end
      end

      # traditional attempt (allows other load hacks to work, including RubyGems)
      #begin
        return require_without_roll(file)
      #rescue LoadError => kernel_error
      #  raise kernel_error if ENV['ROLL_DEBUG']
      #end

      # failure
      #raise kernel_error
    end

    #/--(.*?)$/ =~ e.to_s.strip
    #real_file = $1.strip
    #if real_file != file

    alias_method :load_without_roll, :load

    public :load_without_roll

    # Require script.

    def load(file, wrap=false)
      # specific library
      if file.index(':')
        name, path = file.split(':')
        lib = Library.instance(name)
        raise LoadError, "no library found -- #{file}" unless lib
        return lib.load(path, wrap)
      end

      # potential specified library, ie. head of path is library name
      name, *rest = file.split('/')
      path = File.join(*rest)
      if lib = Library.instance(name)
        begin
          return lib.load(path, wrap)
        rescue LoadError => load_error
          raise load_error if ENV['ROLL_DEBUG']
        end
      end

      # traditional attempt (allows other load hacks to work, including RubyGems)
      #begin
        return load_without_roll(file, wrap)
      #rescue LoadError => kernel_error
      #  raise kernel_error if ENV['ROLL_DEBUG']
      #end

      # failure
      #raise kernel_error
    end


    # This is how require would work if Roll was in charge.
    def require2(file)
      # specific library
      if file.index(':')
        name, path = file.split(':')
        lib = Library.instance(name)
        raise LoadError, "no library found -- #{file}" unless lib
        return lib.require(path)
      end

      # try current library (is this a good idea?)
      if lib = Library.last
        begin
          return lib.require(file)
        rescue LoadError => load_error
          raise load_error if ENV['ROLL_DEBUG']
        end
      end

      # traditional attempt (allows other load hacks to work, including RubyGems)
      #begin
        return require_without_roll(file)
      #rescue LoadError => kernel_error
      #  raise kernel_error if ENV['ROLL_DEBUG']
      #end
    end

    #
    def load2(file, wrap=false)
      # specific library
      if file.index(':')
        name, path = file.split(':')
        lib = Library.instance(name)
        raise LoadError, "no library found -- #{file}" unless lib
        return lib.load(path, wrap)
      end

      # try current library
      if lib = Library.last
        begin
          return lib.load(file, wrap)
        rescue LoadError => load_error
          raise load_error if ENV['ROLL_DEBUG']
        end
      end

      # traditional attempt (allows other load hacks to work, including RubyGems)
      #begin
        return load_without_roll(file, wrap)
      #rescue LoadError => kernel_error
      #  raise kernel_error if ENV['ROLL_DEBUG']
      #end

      # failure
      raise kernel_error
    end

    def last
      Library.load_stack.last
    end

  private

    def parse_load_parameters(file)
      if must = file.index(':')
        name, path = file.split(':')
      else
        name, *rest = file.split('/')
        path = File.join(*rest)
      end
      name = nil if name == ''
      if name
        lib = Library.instance(name)
      else
        lib = nil
      end
      raise LoadError, "no library found -- #{file}" if must && !lib
      return lib, path, must
    end

  end # class << self

end

