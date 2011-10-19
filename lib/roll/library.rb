# Library class encapsulates a location on disc that contains a Ruby
# project, with loadable lib files, of course.
class Library
  require 'roll/core_ext/file'
  require 'roll/library/metadata'
  require 'roll/library/script'
  require 'roll/library/requirements'
  require 'roll/library/version'

  # Dynamic link extension.
  #DLEXT = '.' + ::RbConfig::CONFIG['DLEXT']

  # TODO: Some extensions are platform specific --only
  # add the ones needed for the current platform.
  SUFFIXES = ['.rb', '.rbw', '.so', '.bundle', '.dll', '.sl', '.jar'] #, '']

  # Extensions glob, joins extensions with comma and wrap in curly brackets.
  SUFFIX_PATTERN = "{#{SUFFIXES.join(',')}}"

  # New Library object.
  #
  # If data is given it must have `:name` and `:version`. It can
  # also have `:loadpath`, `:date`, and `:omit`.
  #
  # @param location [String]
  #   expanded file path to library's root directory
  #
  # @param data [Hash]
  #   priming matadata (to circumvent loading it from `.ruby` file)
  #
  def initialize(location, free=false) #, data={})
    @location = location
    @active   = false

    #data = data.rekey

    #if data.empty?
    #  load_metadata
    #else
    #  @name     = data[:name]
    #  @version  = Version.new(data[:version])
    #  @loadpath = data[:loadpath]
    #  @date     = data[:date]  # TODO: convert to Time
    #  @omit     = data[:omit]
    #end

    load_metadata

    raise "Non-conforming library (missing name) -- `#{location}'" unless name
    raise "Non-conforming library (missing version) -- `#{location}'" unless version

    ## if not free and another version is not already active add to ledger
    if $LEDGER && !free
      entry = $LEDGER[name]
      if Array === entry
        entry << self unless entry.include?(self)
      end
    end
  end

  # Activate a library by putting it's loadpaths on the master $LOAD_PATH.
  # This is neccessary only for the fact that autoload will not utilize
  # customized require methods.
  #
  # @return [true] that the library has been activated
  def activate
    return if @active
    vers = $LEDGER[name]
    if Library === vers
      raise VersionConflict.new(self, vers) if vers != self
    else
      if Roll::LEGACY
        lib = vers.first
        if lib != self
          lib.absolute_loadpath.each do |path|
            $LOAD_PATH.delete(path)
          end
          absolute_loadpath.each do |path|
            $LOAD_PATH.unshift(path)
          end
        end
        $LEDGER[name] = self
      else
        # NOTE: we are only doing this for the sake of autoload
        # which does not honor a customized require method.
        absolute_loadpath.each do |path|
          $LOAD_PATH.unshift(path)
        end
        $LEDGER[name] = self
      end
    end
    # TODO: activate runtime dependencies
    #verify
    @active = true
  end

=begin
  # Constrain a library to a single version. This means, if anyone tries
  # to use a different version once a library has been constrained, an
  # VersionConflict error will be raised.
  def constrain
    cmp = $LEDGER[name]
    if Array === cmp
      $LEDGER[name] = self
    else
      if self.version != cmp.version
        raise VersionError
      end
    end
  end
=end

  # Location of library files on disc.
  def location
    @location
  end

  # TODO: If Metadata only came from .ruby file then code could 
  #       be much simplified. Or DotRuby::Spec could be used and gemspec
  #       imported if dotruby-rubygems installed.

  # Access to library metadata.
  #
  # @return [Metadata] metadata object
  #
  # @see Metadata
  def metadata
    @metadata ||= Metadata.new(@location) #, :name=>name)
  end

  #
  #def profile
  #  metadata.profile
  #end

  # Library's requirements.
  #
  # @return [Array] list of requirements
  def requirements
    metadata.requirements
  end

  # Load library metadata. This is gathered from
  # the `.ruby` file or a `.gemspec`.
  #
  # @see Metadata
  def load_metadata
    @name     = metadata.name
    @version  = metadata.version
    @loadpath = metadata.loadpath
    @date     = metadata.date
    @requires = metadata.requires
  end

  # Library's "unixname".
  #
  # @return [String] name of library
  def name
    @name
  end

  # Library's version number.
  #
  # @return [VersionNumber] version number
  def version
    @version
  end

  # Library's internal load path(s). This will default to `['lib']`
  # if not otherwise given.
  #
  # @return [Array] list of load paths
  def loadpath
    @loadpath
  end

  # Release date.
  #
  # @return [Time] library's release date
  def date
    @date
  end

  # Alias for +#date+.
  alias_method :released, :date

  # Runtime dependencies.
  def requires
    @requires
  end

  # Omit library form any ledger?
  #
  # @return [Boolean] omit library from ledgers?
  def omit
    @omit
  end

  # Same as `#omit`.
  alias_method :omit?, :omit

  # Returns a list of load paths expand to full path names.
  #
  # @return [Array<String>] list of expanded load paths
  def absolute_loadpath
    loadpath.map{ |lp| ::File.join(location, lp) }
  end

  # Take runtime dependencies and open them. This will help reveal any
  # version conflicts or missing dependencies.
  def verify
    requires.each do |(name, constraint)|
      Library.open(name, constraint)
    end
  end

  # Take all dependencies and open it. This will help reveal any
  # version conflicts or missing dependencies.
  def verify_all
    requirements.each do |(name, constraint)|
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
  # NOTE: This method was designed to maximize speed.
  def find(file, options={})
    main   = options[:main]
    legacy = options[:legacy]
    suffix = options[:suffix] || options[:suffix].nil?
    #suffix = false if options[:load]
    suffix = false if SUFFIXES.include?(::File.extname(file))
    if suffix
      SUFFIXES.each do |ext|
        loadpath.each do |lpath|
          f = ::File.join(location, lpath, file + ext)
          return libfile(lpath, file, ext) if ::File.file?(f)
        end unless legacy
        legacy_loadpath.each do |lpath|
          f = ::File.join(location, lpath, file + ext)
          return libfile(lpath, file, ext) if ::File.file?(f)
        end unless main
      end
    else
      loadpath.each do |lpath|
        f = ::File.join(location, lpath, file)        
        return libfile(lpath, file) if ::File.file?(f)
      end unless legacy
      legacy_loadpath.each do |lpath|
        f = ::File.join(location, lpath, file)        
        return libfile(lpath, file) if ::File.file?(f)
      end unless main
    end
    nil
  end

=begin
  def find(file, options={})
    legacy = options[:legacy]
    suffix = options[:suffix] || options[:suffix].nil?
    #suffix = false if options[:load]
    suffix = false if SUFFIXES.include?(::File.extname(file))
    lp = loadpath()
    if suffix
      if legacy
        SUFFIXES.each do |ext|
          lp.each do |lpath|
            f = ::File.join(location, lpath, file + ext)
            return libfile(lpath, file, ext) if ::File.file?(f)
          end
        end
      else
        SUFFIXES.each do |ext|
          lp.each do |lpath|
            f = ::File.join(location, lpath, file + ext)
            return libfile(lpath, file, ext) if ::File.file?(f)
            #f = ::File.join(location, lpath, name, file + ext)               
            #return libfile(::File.join(lpath, name), file, ext) if ::File.file?(f)
          end
        end
      end
    else
      if legacy
        lp.each do |lpath|
          f = ::File.join(location, lpath, file)
          return libfile(lpath, file) if ::File.file?(f)
        end
      else
        lp.each do |lpath|
          f = ::File.join(location, lpath, file)        
          return libfile(lpath, file) if ::File.file?(f)
          #f = ::File.join(location, lpath, name, file)
          #return libfile(::File.join(lpath, name), file) if ::File.file?(f)
        end
      end
    end
    nil
  end
=end

  # Alias for #find.
  alias_method :include?, :find

=begin
  # Does a library contain a relative +file+ within it's loadpath.
  # If so return the libary file object for it, otherwise +false+.
  def include?(file, options={})
    legacy = options[:legacy]
    suffix = options[:suffix] || options[:suffix].nil?
    #suffix = false if options[:load]
    suffix = false if SUFFIXES.include?(::File.extname(file))
    if suffix
      SUFFIXES.each do |ext|
        loadpath.each do |lpath|
          f = ::File.join(location, lpath, file + ext)
          return libfile(lpath, file, ext) if ::File.file?(f)
        end unless legacy
        legacy_loadpath.each do |lpath|
          f = ::File.join(location, lpath, file + ext)
          return libfile(lpath, file, ext) if ::File.file?(f)
        end         
      end
    else
      loadpath.each do |lpath|
        f = ::File.join(location, lpath, file)        
        return libfile(lpath, file) if ::File.file?(f)
      end unless legacy
      legacy_loadpath.each do |lpath|
        f = ::File.join(location, lpath, file)        
        return libfile(lpath, file) if ::File.file?(f)
      end
    end
    nil
  end
=end

  #
  def legacy?
    !legacy_loadpath.empty?
  end

  def legacy_loadpath
    @legacy_loadpath ||= (
      path = []
      loadpath.each do |lp|
        llp = File.join(lp, name)
        dir = File.join(location, llp)
        path << llp if File.directory?(dir)
      end
      path
    )
  end

  # Create a new LibFile object from +lpath+, +file+ and +ext+.
  def libfile(lpath, file, ext=nil)
    LibFile.new(self, lpath, file, ext)
  end

  #
  def require(path, options={})
    if file = include?(path, options)
      file.require(options)
    else
      # TODO: silently?
      raise LoadError.new(path, name)
    end
  end

  #
  def load(path, options={})
    if file = include?(path, options)
      file.load(options)
    else
      raise LoadError.new(path, name)
    end
  end

  #
  def isolate(options={})
    if options[:all]
      list = Library.environments
    else
      list = [Library.environment]
    end

    results = library.requirements.verify

    fails, libs = results.partition{ |r| Array === r }
  end

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
    @default ||= include?(name, :main=>true)
  end

  #--
  #    # List of subdirectories that are searched when loading.
  #    #--
  #    # This defualts to ['lib/{name}', 'lib']. The first entry is
  #    # usually proper location; the latter is added for default
  #    # compatability with the traditional require system.
  #    #++
  #    def libdir
  #      loadpath.map{ |path| ::File.join(location, path) }
  #    end
  #
  #    # Does the library have any lib directories?
  #    def libdir?
  #      lib.any?{ |d| ::File.directory?(d) }
  #    end
  #++

  # Location of executable. This is alwasy bin/. This is a fixed
  # convention, unlike lib/ which needs to be more flexable.
  def bindir  ; ::File.join(location, 'bin') ; end

  # Is there a <tt>bin/</tt> location?
  def bindir? ; ::File.exist?(bindir) ; end

  # Location of library system configuration files.
  # This is alwasy the <tt>etc/</tt> directory.
  def confdir ; ::File.join(location, 'etc') ; end

  # Is there a <tt>etc/</tt> location?
  def confdir? ; ::File.exist?(confdir) ; end

  # Location of library shared data directory.
  # This is always the <tt>data/</tt> directory.
  def datadir ; ::File.join(location, 'data') ; end

  # Is there a <tt>data/</tt> location?
  def datadir? ; ::File.exist?(datadir) ; end

  #
  #def to_rb
  #  to_h.inspect
  #end

  # Convert to hash
  def to_h
    {
      :name     => name,
      :version  => version.to_s,
      :loadpath => loadpath,
      :date     => date,
      :requires => requires
    }
  end

  # C L A S S  M E T H O D S

# temporary
$MONITOR = ENV['roll_monitor']

  # Find matching libary files. This is the "mac daddy" method used by
  # the #require and #load methods to find the specified +path+ among
  # the various libraries and their loadpaths.
  def self.find(path, options={})
    path   = path.to_s

    suffix = options[:suffix]
    search = options[:search]
    legacy = options[:legacy]

$stderr.print path if $MONITOR

    # Ruby appears to have a special exception for enumerator!!!
    #return nil if path == 'enumerator' 

    # absolute path
    if /^\// =~ path
$stderr.puts "  (0 absolute)" if $MONITOR
      return nil
    end

    if path.index(':') # a specified library
      name, fname = path.split(':')
      lib  = library(name)
      file = lib.include?(fname, options)
      raise LoadError, "no such file to load -- #{path}" unless file
$stderr.puts "  (1 direct)" if $MONITOR
      return file
    end

    if not legacy
      # try the load stack (TODO: just last or all?)
      if libfile = $LOAD_STACK.last
      #$LOAD_STACK.reverse_each do |libfile|
        lib = libfile.library
        #if file = lib.include?(fname, options)
        if file = lib.include?(path, options)
          unless $LOAD_STACK.include?(file)
  $stderr.puts "  (2 stack)" if $MONITOR
            return file
          end
        end
      end
    end

    name, fname = ::File.split_root(path)

    # if the head of the path is the library
    if fname #path.index('/') or path.index('\\')
      lib = Library[name]
      if lib && file = lib.include?(fname, options)
$stderr.puts "  (3 indirect)" if $MONITOR
        return file
      end
    end

    # plain library name?
    if !fname && lib = Library.instance(path)
      if file = lib.default # default file to load
$stderr.puts "  (5 plain library name)" if $MONITOR
        return file
      end
    end

=begin
    # try site_ruby
    lib = Library['site_ruby']
    if file = lib.include?(path, options)
$stderr.puts "  (4 ruby core)" if $MONITOR
      return file
    end

    # try ruby
    lib = Library['ruby']
    if file = lib.include?(path, options)
$stderr.puts "  (4 ruby core)" if $MONITOR
      return file
    end
=end

    # fallback to brute force search, if desired
    if search #or legacy
      #options[:legacy] = true
      if file = search(path, options)
$stderr.puts "  (6 brute search)" if $MONITOR
        return file
      end
    end

$stderr.puts "  (7 fallback)" if $MONITOR
    nil
  end

  # Brute force search looks through all libraries for a matching file.
  #
  # path    - file path for which to search
  # options: 
  #   :select -
  #   :suffix -
  #   :legacy -
  #
  # Returns either
  def self.search(path, options={})
    matches = []

    select  = options[:select]
    suffix  = options[:suffix] || options[:suffix].nil?
    #suffix = false if options[:load]
    suffix = false if Library::SUFFIXES.include?(::File.extname(path))

    # TODO: Perhaps the selected and unselected should be kept in separate lists?
    unselected, selected = *$LEDGER.partition{ |name, libs| Array === libs }

    ## broad search of pre-selected libraries
    selected.each do |(name, lib)|
      if file = lib.find(path, options)
        next if Library.load_stack.last == file
        return file unless select
        matches << file
      end
    end

    ## finally try a broad search on unselected libraries
    unselected.each do |(name, libs)|
      pos = []
      libs.each do |lib|
        if file = lib.find(path, options)
          pos << file
        end
      end
      unless pos.empty?
        latest = pos.sort{ |a,b| b.library.version <=> a.library.version }.first
        return latest unless select
        matches << latest
      end
    end

    ## last ditch attempt, search all $LOAD_PATH
    if suffix
      SUFFIXES.each do |ext|
        $LOAD_PATH.each do |location|
          file = ::File.join(location, path + ext)
          if ::File.file?(file)
            return Library::LibFile.new(location, '.', path, ext)
            matches << file 
          end
        end
      end
    else
      $LOAD_PATH.each do |location|
        file = ::File.join(location, file)
        if ::File.file?(file)
          return Library::LibFile.new(location, '.', path, ext) unless select
          matches << file
        end
      end
    end

    select ? matches.uniq : matches.first
  end

  # Search Roll system for current or latest library files. This is useful
  # for plugin loading.
  #
  # This only searches activated libraries or the most recent version
  # of any given library.
  #
  def self.find_files(match, options={})
    matches = []
    ledger.each do |name, lib|
      lib = lib.sort.first if Array===lib
      lib.loadpath.each do |path|
        find = File.join(lib.location, path, match)
        list = Dir.glob(find)
        list = list.map{ |d| d.chomp('/') }
        matches.concat(list)
      end
    end
    matches
  end


  # Current ledger.
  def self.ledger
    $LEDGER
  end

  # Access to global load stack.
  def self.load_stack
    $LOAD_STACK
  end

  #
  def self.names
    $LEDGER.keys
  end

  #
  def self.list
    $LEDGER.keys
  end

  # A shortcut for #instance.
  #
  # @return [Library] an instance of Library
  def self.[](name, constraint=nil)
    instance(name, constraint)
  end

  # Get an instance of a library by name, or name and version.
  # Libraries are singleton, so once loaded the same object is
  # always returned.
  def self.instance(name, constraint=nil)
    name = name.to_s
    #raise "no library -- #{name}" unless include?(name)
    return nil unless $LEDGER.include?(name)

    library = $LEDGER[name]

    if Library===library
      if constraint # FIXME: it's okay if constraint fits current
        raise Library::VersionConflict, library
      else
        library
      end
    else # library is an array of versions
      if constraint
        compare = Library::Version.constraint_lambda(constraint)
        library = library.select{ |lib| compare[lib.version] }.max
      else
        library = library.max
      end
      unless library
        raise VersionError, "no library version -- #{name} #{constraint}"
      end
      #index[name] = library #constrain(library)
      library.activate
      return library
    end
  end

  # Activate a library. Same as #instance but will raise and error if the
  # library is not found. This can also take a block to yield on the library.
  #
  # @param [String]
  #   name of library
  #
  # @param [String]
  #   valid version constraint
  #
  # @return [Library]
  #   the activated Library object
  #
  # TODO: Should we also check $"? Eg. `return false if $".include?(path)`.
  def self.activate(name, constraint=nil) #:yield:
    library = instance(name, constraint)
    unless library
      raise LoadError, "no library -- #{name}"
    end
    library.activate
    yield(library) if block_given?
    library
  end

  # Acquire a script within the library.
  #
  # @param path [String]
  #   file name of script relative to library's loadpath
  #
  # @param options [Hash]
  #
  #
  # @return [true, false] if script was newly required or successfully loaded
  def self.acquire(path, options)
    if file = $LOAD_CACHE[path]
      if options[:load]
        return file.load
      else
        return false
      end
    end

    if file = Library.find(path, options)
      #file.library_activate
      $LOAD_CACHE[path] = file
      return file.acquire(options)
    end

    if options[:load]
      load_without_rolls(path, options[:wrap])
    else
      require_without_rolls(path)
    end
  end

  # Roll-style loading. First it looks for a specific library via `:`.
  # If `:` is not present it then tries the current loading library.
  # Failing that it fallsback to Ruby itself.
  #
  #   require('facets:string/margin')
  #
  # To "load" the library, rather than "require" it, set the +:load+
  # option to true.
  #
  #   require('facets:string/margin', :load=>true)
  #
  # @param path [String]
  #   file name of script relative to library's loadpath
  #
  # @return [true, false] if script was newly required
  def self.require(path, options={}) #, &block)
    #options.merge!(block.call) if block
    options[:legacy] = true
    acquire(path, options)
  end

  # Load file path. This is just like #require except that previously
  # loaded files will be reloaded and standard extensions will not be
  # automatically appended.
  #
  # @param path [String]
  #   file name of script relative to library's loadpath
  #
  # @return [true, false] if script was successfully loaded
  def self.load(path, options={}) #, &block)
    #options.merge!(block.call) if block

    options[:wrap]   = true if options and !(Hash===options)
    options[:load]   = true
    options[:suffix] = false
    options[:legacy] = true

    acquire(path, options)

    #if file = $LOAD_CACHE[path]
    #  return file.load
    #end

    #if file = Library.find(path, options)
    #  #file.library_activate
    #  $LOAD_CACHE[path] = file
    #  return file.load(options) #acquire(options)
    #end

    ##if options[:load]
    #  load_without_rolls(path, options[:wrap])
    ##else
    ##  require_without_rolls(path)
    ##end
  end

  # Return Array of environment names.
  def self.environments
    Environment.list
  end

  #
  def self.environment(name=nil)
    Environment[name]
  end

  #
  #def self.autoload(constant, file)
  #  ledger.autoload(constant, file)
  #end

  class LoadError < ::LoadError
    def initialize(failed_path, library_name=nil)
      super()
      @failed_path  = failed_path
      @library_name = library_name
      clean_backtrace
    end

    def to_s
      "no such file to load -- #{@library_name}:#{@failed_path}"
    end

    # Take an +error+ and remove any mention of 'roll' from it's backtrace.
    # Will leave the backtrace untouched if $DEBUG is set to true.
    def clean_backtrace
      return if ENV['roll_debug'] || $DEBUG
      bt = backtrace
      bt = bt.reject{ |e| /roll/ =~ e } if bt
      set_backtrace(bt)
    end
  end

end

