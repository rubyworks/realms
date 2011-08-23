module Roll

  #
  LEGACY = ENV['ROLL_LEGACY'] != 'false'

  #
  DEFAULT_ROLL = 'master'

  # Setup the ledger.
  #
  def self.bootstrap(name=nil)
    require_without_rolls 'roll/ruby'

    $ROLL_FILE = roll_file

    #$LOAD_GROUP = []
    $LOAD_STACK = []
    $LOAD_CACHE = {}

    if File.exist?(lock_file)
      ledger = YAML.load(File.new(lock_file))  
      $LEDGER = Hash.new{|h,k| h[k] = []}
      $LEDGER.merge!(ledger)
    elsif File.exist?($ROLL_FILE)
      $LEDGER = load_ledger($ROLL_FILE)
    else
      $LEDGER = {}
    end

    # Legacy mode manages a traditional loadpath.
    if LEGACY
      $LEDGER.each do |name, libs|
        #next if name == 'ruby'
        #next if name == 'site_ruby'
        sorted_libs = [libs].flatten.sort
        lib = sorted_libs.first
        lib.absolute_loadpath.each do |path|
          $LOAD_PATH.unshift(path)
        end
      end
    end

    $LEDGER['site_ruby'] = SiteRubyLibrary.new
    $LEDGER['ruby']      = RubyLibrary.new

    #$LEDGER = ledger
  end

  #
  def self.config_home
    File.join(XDG.config_home, 'roll')
  end

  #
  def self.roll_file
    file = ENV['RUBYENV'] || ENV['roll_file'] || DEFAULT_ROLL
    construct_roll_file(file)
  end

  #
  def self.lock_file
    roll_file.chomp('.roll') + '.lock'
  end

  # Construct ledger using pathnames in given `file`.
  def self.load_ledger(file)
    make_ledger(File.readlines(file))
  end

  # Construct a ledger.
  def self.make_ledger(paths)
    ledger = Hash.new{|h,k| h[k] = []}

    paths.each do |path|
      path = path.strip
      next if path[0,1] == '#'
      next if path.empty?
      if File.directory?(path)
        begin
          library = Library.new(path, true)
          ledger[library.name] << library
        rescue Exception => error
          warn error.message if ENV['roll_debug']
          #warn "invalid library path -- `#{path}'" if ENV['roll_debug']
        end
      else
        warn "invalid library path -- `#{path}'" if ENV['roll_debug']
      end
    end

    ledger
  end

  # Lock a ledger.
  #
  # @return [String] full pathname of cache file
  def self.lock(file=nil, options={})
    if file
      ledger = Roll.load_ledger(file)
      output = options[:output] || file + '.lock'
    else
      ledger = $LEDGER
      output = options[:output] || Roll.lock_file
    end

    File.open(output, 'w+') do |f|
      f << ledger.to_yaml
    end

    return output
  end

  # Remove the current ledger's lock.
  #
  # @return [String] full pathname of cache file
  def self.unlock
    FileUtils.rm(lock_file) if File.exist?(lock_file)
    return lock_file
  end

  # Insert path into current roll.
  #
  # @return [String] roll file
  def self.insert(*paths)
    paths.map!{ |path| File.expand_path(path) }
    File.open(roll_file, 'a') do |file|
      file << "\n"
      file << paths.join("\n")
    end
    roll_file
  end

  # Remove path(s) from current roll.
  #
  # @return [String] roll file
  def self.remove(*paths)
    paths.map!{ |path| File.expand_path(path) }
    list = File.readlines(roll_file)
    list = list - paths
    File.open(roll_file, 'w') do |file|
      file << list.join("\n")
    end
    roll_file
  end

  #
  def self.construct_roll_file(path)
    if name?(path)
      file = File.join(config_home, path) + '.roll'
    else
      file = File.expand_path(path)
      ## TODO: should we bother with this?
      if File.extname(file) != 'roll' && !File.exist?(file)
        file = file + '.roll' if File.exist?(file + '.roll')
      end
    end
    file
  end

  # Is the given file a path (as opposed to just a name)?
  def self.path?(file)
    /\W/ =~ file
  end

  # Is the given file just a name (as opposed to  a path)?
  def self.name?(file)
    /\W/ !~ file
  end

  # Does this location have .ruby/ entries?
  #--
  # TODO: Really it should at probably have a `version` too.
  #++
  def self.dotruby?(location)
    file = ::File.join(location, '.ruby')
    return false unless File.file?(file)
    return true
  end

  # Return list of locked rolls.
  def self.locked_rolls
    Dir[File.join(config_home, '*.lock')].map do |file|
      file.chomp('.lock') + '.roll'
    end
  end

end
