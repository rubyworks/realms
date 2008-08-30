require 'roll/corepatch'

# = Library Qua-Class
#
# The Library-Qua-Class serves as the library manager,
# storing a ledger of available libraries.
#
metaclass Library do

  # We need to hold a copy of the original $LOAD_PATH
  # for specified "ruby: ..." loads.
  $RUBY_PATH = $LOAD_PATH.dup

  # TODO: Use this too!!!
  #SYSTEM_LEDGER_FILE = File.join(Config::CONFIG['sysconfdir'], 'roll', 'ledger.list')

  # LEDGER FILE
  #CACHE_FILE = File.join(ENV['HOME'], '.etc', 'roll', 'ledger.list')

  # SERACH DEPTH
  #DEPTH = 4

  #
  attr :ledger

  #
  attr :locations

  # Setup Library system.
  def setup #(live=false)
    @ledger    = {}
    @locations = []

    # First we add Ruby's core and standard libraries to the ledger.
    @ledger['ruby'] = Library.new(
      Library.rubylibdir,
      :name=>'ruby',
      :version=>RUBY_VERSION,
      :libpath=>Library.ruby_path
    )

    locations = []
    ledger_files.each do |file|
      locs = File.read(file).split(/\s*\n/)
      locations.concat(locs)
    end

    load_projects(*locations)
  end

  def ledger_files
    @ledger_files ||=(
      files = []
      files << user_ledger_file if File.exist?(user_ledger_file)
      files << system_ledger_file if File.exist?(system_ledger_file)
      files
    )
  end

  # TODO: Use XDG standard.
  def user_ledger_file
    @user_ledger_file ||= File.join(ENV['HOME'], '.etc', 'roll', 'ledger.list')
  end

  # TODO: Use XDG standard.
  def system_ledger_file
    @system_ledger_file ||= File.join(Config::CONFIG['sysconfdir'], 'roll', 'ledger.list')
  end

=begin
  #
  def live_load
    find(search_depth, *$LOAD_SITE)
  end

  #
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
=end

  #
  def load_projects(*locations)
    locations.each do |location|
      begin
        metadata = load_rollfile(location)
        versdata = load_version(location)
        metadata.update(versdata)

        metadata[:name] ||= metadata[:project] || metadata[:title].downcase

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
    return {} unless File.exist?(rollfile)

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

  # Load and parse version stamp file.
  def load_version(location)
    patt = File.join(location,'{,meta/}VERSION')
    file = Dir.glob(patt, File::FNM_CASEFOLD).first
    if file
      parse_version_stamp(File.read(file))
    else
      {}
    end
  end

  #
  def parse_version_stamp(text)
    #info, *libpath = *data.split(/\s*\n\s*/)
    name, version, status, date = text.split(/\s+/)
    version = VersionNumber.new(version)
    date    = Time.mktime(*date.scan(/[0-9]+/))
    #default = default || "../#{name}"
    return {:name => name, :version => version, :status => status, :date => date}
  end

  # Update cache.
  def update_cache
    setup(true) # live setup
    FileUtils.mkdir_p(File.dirname(CACHE_FILE))
    File.open(CACHE_FILE, 'w') do |f|
      f << locations.join("\n")
    end
  end

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

  # Load stack stores a list of libraries, where the one
  # on top of the stack is the one current loading.
  def load_stack
    @load_stack ||= []
  end

  # The current library.
  def last
    Library.load_stack.last
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
  #public :require_without_roll

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
      raise LoadError, "no library found -- #{name}" unless lib
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
  #public :load_without_roll

  # Load script.
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

private

  #
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

end

