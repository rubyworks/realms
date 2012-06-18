#require 'facets/load/monitor' # used for debugging

module Roll

  # Roll management console.
  #
  module Console

    # TODO: What about supporting multiple roll files at once? Call it a "ROLLSTACK".

    #
    # The environment variable used to specify the current roll.
    #
    ENVIRNMENT_VARIABLE = 'RUBYROLL'

    #
    # The default roll to use, if none is specified.
    #
    DEFAULT_ROLLNAME = 'default'

    #
    # Setup the Ruby on Rolls.
    #
    def bootstrap(name=nil)
      require 'library'
      require 'library/rubylib'

      $LEDGER = Library::Ledger.new

      if !roll_file
        warn "no such roll -- `#{rollname}'"
        return
      end

      if File.exist?(lock_file)
        ledger = YAML.load(File.new(lock_file))  

        # TODO: Put RUBYENV in serialized ledger
        #ENV['RUBYENV'] = ledger.delete('RUBYENV')

        $LEDGER.replace(ledger)
      else
        paths = load_roll(roll_file)

        # TODO: Use semicolon on Windows ?
        ENV['RUBYLIBS'] = paths.join(':')

        Library.prime(*paths) #, :exound=>true)
      end

      #bootstrap_legacy if legacy?

      # We can not do this b/c it prevents gems from working
      # when a file has the same name as something in the
      # ruby lib and site locations. For example, if we intsll
      # the test-unit gem and require `test/unit`.
      #$LEDGER['ruby'] = RubyLibrary.new

      require 'library/kernel'
    end

    #
    #def legacy?
    #  ENV['roll_legacy'] != 'false'
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

    # dirs = []
    # dirs << ENV['XDG_CONFIG_HOME'] || File.join(home, '.config')
    # dirs << ENV['XDG_CONFIG_DIRS'].to_s.split(/[:;]/)
    # XDG_CONFIG_PATHS = dirs.flatten.map{ |dir| [File.expand_path(dir) }

    #
    #
    #
    def config_paths
      @config_paths ||= (
        paths = []
        paths << File.expand_path("~/.roll")
        paths << File.expand_path("~/.config/roll")
        paths << "/etc/roll"
        paths.select{ |path| File.directory?(path) }
      )
    end

    #
    # Find Roll configuration file.
    #
    def find_config(file)
      config_paths.each do |path|
        f = File.join(path, file)
        return f if File.exist?(f)
      end
      nil
    end

    #
    # Search Roll's config locations for mathing file glob.
    #
    def search_config(glob)
      list = []
      config_paths.each do |path|
        list.concat(Dir[File.join(path, glob)])
      end
      list
    end

    #
    # Return array of available rolls.
    #
    def available_rolls
      search_config('*.roll').map { |r| File.basename(r).chomp('.roll') }
    end

    #
    # The Roll file to use.
    #
    def roll_file(name=nil)
      @roll_file ||= {}

      name ||= rollname()

      return @roll_file[name] unless @roll_file[name].nil?

      @roll_file[name] = (
        file = false
        if name?(name)
          file = find_config(name + '.roll')
        else
          file = File.expand_path(name)
          file = file + '.roll' if File.extname(file) != '.roll' && !File.exist?(file)
          file = false unless File.exist?(file)
        end

        file || false
      )
    end

    #
    # Lock file is the same a roll_file but will `.lock` extension.
    #
    def lock_file
      roll_file.chomp('.roll') + '.lock'
    end

    #
    # Selected roll. This will either be a name coresponding to a file in the
    # standard configuration locations (`~/.roll`, `~/.config/roll` or `/etc/roll`),
    # or it can be a pathname to an otherwise located file.
    #
    def rollname
      @rollname ||= ENV[ENVIRNMENT_VARIABLE] || rollname_from_file ||  DEFAULT_ROLLNAME
    end

    #
    # Typically the roll is configured by environment variable (`RUBYROLL`) but
    # if need be it can be configured via a config file of the same name.
    #
    def rollname_from_file
      if file = find_config('RUBYROLL')
        File.read(file).strip
      else
        nil
      end
    end

    #
    # Construct ledger using pathnames in given `file`.
    #
    #def load_ledger(file)
    #  make_ledger(File.readlines(file))
    #end

    #
    # Construct a ledger.
    #
    def load_roll(file)
      list = []

      paths = File.readlines(file)
      paths = paths.map{ |g| Dir[g.strip] }.flatten

      paths.each do |path|
        path = path.strip

        next if path[0,1] == '#'
        next if path.empty?

        if !File.directory?(path)
          warn "invalid library path -- `#{path}'" if ENV['debug']
          next
        end

        #begin
          list << path
        #rescue Exception => error
        #  warn error.message if ENV['debug']
        #  #warn "invalid library path -- `#{path}'" if ENV['roll_debug']
        #end
      end

      list
    end

    #
    # FIXME: This should be done via Library::Ledger somehow.
    # Could use prime_expound.
    #
    def make_ledger(file)
      list = load_roll(file)
      ledger = Library::Ledger.new
      list.each do |path|
        ledger << path
      end
      ledger
    end

    #
    # Lock a ledger.
    #
    # @return [String] full pathname of lock file.
    #
    def lock(file=nil, options={})
      if file
        ledger = make_ledger(file)
        output = options[:output] || file + '.lock'
      else
        ledger = $LEDGER
        output = options[:output] || lock_file
      end

      File.open(output, 'w+') do |f|
        f << ledger.to_yaml
      end

      return output
    end

    #
    # Remove a ledger lock.
    #
    # @param [String] name
    #   Name of roll. If not given the curent roll is used.
    #
    # @return [String] Full pathname of cache file.
    #
    def unlock(name=nil)
      file = roll_file(name)
      raise IOError, "#{name} is not a roll" unless file
      lock_file = file.chomp('.roll') + '.lock'
      if File.exist?(lock_file)
        File.delete(lock_file)
        lock_file
      else
        nil
      end
    end

    #
    # Insert path into current roll.
    #
    # @return [String] roll file
    #
    def insert(*paths)
      paths.map!{ |path| File.expand_path(path) }
      File.open(roll_file, 'a') do |file|
        file << "\n"
        file << paths.join("\n")
      end
      roll_file
    end

    #
    # Remove path(s) from current roll.
    #
    # @return [String] roll file
    #
    def remove(*paths)
      paths.map!{ |path| File.expand_path(path) }
      list = File.readlines(roll_file)
      list = list - paths
      File.open(roll_file, 'w') do |file|
        file << list.join("\n")
      end
      roll_file
    end

    #
    # Does this location have a .ruby file?
    #
    def dotruby?(location)
      file = ::File.join(location, '.ruby')
      return false unless File.file?(file)
      return true
    end

    #
    # Return list of locked rolls.
    #
    def locked_rolls
      Dir[File.join(config_home, '*.lock')].map do |file|
        file.chomp('.lock') + '.roll'
      end
    end

    #
    #
    #
    def copy(dst, src=nil, opts={})
      if src
        src = Roll.construct_roll_file(src)
        dst = Roll.construct_roll_file(dst)
      else
        src = Roll.roll_file
        dst = Roll.construct_roll_file(dst)
      end

      safe_copy(src, dst)

      if opts[:lock]
        Roll.lock(dst)
        puts "Locked '#{dst}`."
      else
        puts "Saved '#{dst}`."
      end
    end

    #
    # Lock rolls that contain locations relative to the current gem home.
    #
    # @todo Better name for this method ?
    #
    # @return [Array<String>] list of roll files that were re-locked
    #
    def lock_gem_rolls
      relock = []

      locked_rolls.each do |file|
        File.each_line do |path|
          path = path.strip
          if gem_path?(path)
            relock << file
            break
          end
        end
      end

      relock.each do |file|
        lock(file)
      end

      relock
    end

  private

    #
    # Copy a file safely.
    #
    def safe_copy(src, dst)
      if not File.exist?(src)
        $stderr.puts "File does not exist -- '#{src}`"
        exit -1
      end
      if File.exist?(dst) && !opts[:force]
        $stderr.puts "'#{dst}` already exists. Use --force option to overwrite."
        exit -1
      end
      FileUtils.cp(src, dst)
    end

    #
    # Is the given file a path (as opposed to just a name)?
    #
    def path?(file)
      /\W/ =~ file
    end

    #
    # Is the given file just a name (as opposed to  a path)?
    #
    def name?(file)
      /\W/ !~ file
    end

    #
    # Does the current roll include any entires that lie within
    # the current gem home?
    #
    def gem_path?(path)
      dir = ENV['GEM_HOME'] || gem_home
      rex = ::Regexp.new("^#{Regexp.escape(dir)}\/")
      rex =~ path
    end

    #
    # Default gem home directory path.
    #
    # @return [String] Gem home path.
    #
    def gem_home
      if defined? RUBY_FRAMEWORK_VERSION then
        File.join File.dirname(CONFIG["sitedir"]), 'Gems', CONFIG["ruby_version"]
      elsif CONFIG["rubylibprefix"] then
        File.join(CONFIG["rubylibprefix"], 'gems', CONFIG["ruby_version"])
      else
        File.join(CONFIG["libdir"], ruby_engine, 'gems', CONFIG["ruby_version"])
      end
    end

  end

  # Extend Roll with Management functions.
  extend Console

end
