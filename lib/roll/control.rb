module Roll

  # Setup the ledger.
  #
  def self.bootstrap(name=nil)
    #require_without_library 'library/ruby'

    $ROLL_FILE = roll_file

    #$LOAD_GROUP = []

    $LEDGER = Library::Ledger.new

    if File.exist?(lock_file)
      ledger = YAML.load(File.new(lock_file))  
      $LEDGER.merge!(ledger)
    elsif File.exist?($ROLL_FILE)
      load_ledger($ROLL_FILE)
    #else
    #  $LEDGER = {}
    end

    #bootstrap_legacy if legacy?

    #$LEDGER['site_ruby'] = RubySiteLibrary.new
    $LEDGER['ruby']      = RubyLibrary.new
  end

  #
  #def self.legacy?
  #  ENV['roll.legacy'] != 'false'
  #end

  ## Legacy mode manages a traditional loadpath.
  #def bootstrap_legacy
  #  return unless legacy?
  #  $LEDGER.each do |name, libs|
  #    #next if name == 'ruby'
  #    #next if name == 'site_ruby'
  #    sorted_libs = [libs].flatten.sort
  #    lib = sorted_libs.first
  #    lib.absolute_loadpath.each do |path|
  #      $LOAD_PATH.unshift(path)
  #    end
  #  end
  #end

  #
  #def self.autoload_hack?
  #  ENV['roll_autoload']
  #end

  #
  def self.config_home
    @config_home ||= (
      path = File.expand_path("~/.roll")
      if File.exist(path)
        path
      else
        File.join(XDG.config_home, 'roll')
      end
    )
  end

  #
  def self.search_config(file)
    XDG.search_config(File.join('roll', file))
  end

  #
  DEFAULT_ROLL = 'current'

  # Return Array of environment names.
  def self.environments
    @environments ||= search_config('*.roll').map { |r| File.basename(r).chomp('.roll') }
  end

#  #
#  def self.environment(name=nil)
#    Environment[name]
#  end

  #
  def self.roll_file
    roll = ENV['roll'] || ENV['RUBYENV'] || rollenv_from_file ||  DEFAULT_ROLL

    file = nil

    if name?(roll)
      file = search_config(roll + '.roll').first
    else
      file = File.expand_path(roll)
      file = file + '.roll' if File.extname(file) != 'roll' && !File.exist?(file)
      file = nil unless File.exist?(file)
    end

    # TODO: what to do if file is nil ?

    file
  end

  #
  def self.lock_file
    roll_file.chomp('.roll') + '.lock'
  end

  #
  def self.rollenv_from_file
    if File.exist?(rollenv_file)
      File.read(rollenv_file).strip
    else
      nil
    end
  end

  #
  def self.rollenv_file
    @rollenv_file ||= search_config('rollenv')    
  end

  # Construct ledger using pathnames in given `file`.
  def self.load_ledger(file)
    make_ledger(File.readlines(file))
  end

  # Construct a ledger.
  def self.make_ledger(paths)
    #ledger = Library::Ledger.new #Hash.new{|h,k| h[k] = []}

    paths = paths.map{ |g| Dir[g.strip] }.flatten

    paths.each do |path|
      path = path.strip

      next if path[0,1] == '#'
      next if path.empty?

      if !File.directory?(path)
        warn "invalid library path -- `#{path}'" if ENV['debug']
        next
      end

      begin
        Library.add(path)
        #library = Library.new(path)
        #ledger[library.name] << library
      rescue Exception => error
        warn error.message if ENV['debug']
        #warn "invalid library path -- `#{path}'" if ENV['roll_debug']
      end
    end

    #ledger
  end


#    # Load up the ledger with a given set of paths.
#    def load_ledger(paths)
#      # TODO: should we be globbing here?
#      paths = paths.map{ |g| Dir[g.strip] }.flatten
#
#      paths.each do |path|
#        path = path.strip
#
#        next if path[0,1] == '#'
#        next if path.empty?
#
#        if !File.directory?(path)
#          warn "invalid library path -- `#{path}'" if ENV['debug']
#          next
#        end
#
#        $LEDGER << path
#      end
#    end
#
#    #
#    def library_path?(path)
#      return false unless File.directory?(path)
#    end


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

  # Does this location have a .ruby file?
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

private

  # Is the given file a path (as opposed to just a name)?
  def self.path?(file)
    /\W/ =~ file
  end

  # Is the given file just a name (as opposed to  a path)?
  def self.name?(file)
    /\W/ !~ file
  end

end
