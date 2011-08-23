module Roll

  #
  # @return [Configuration] roll configuration object
  def config
    @config ||= Configuration.new
  end

  #
  class Configuration

    # Get a setting's value. A setting is read either from the user's
    # home settings files or from environment variables.
    def [](name)
      name = name.to_s.downcase
      file = File.join(home_settings_directory, name)
      if File.file?(file)
        val = File.read(file).strip
        val = nil if val.empty?
      else
        var = "roll_#{name}"
        val = ENV[var] || ENV[var.upcase]
      end
      val
    end

    #
    def roll_file
      self['file']
    end

    #
    def roll_name
      self['name']
    end

    # Default environment name, looks for `default_name` setting,
    # otherwise uses DEFAULT_NAME constant. If no current name is set,
    # this value will be used.
    #
    # @return [String] default environment name
    def default_name
      @default_name ||= self['default_name'] || DEFAULT_NAME
    end

    # Default environment file.
    #
    # @return [String, nil] default environment file name
    def default_file
      @default_file ||= self['default_file']
    end

    # Home configuration directory.
    def home_directory
      File.join(XDG.config_home, 'roll')
    end

    # Cache directory.
    def cache_directory
      File.join(XDG.cache_home, 'roll')
    end

    ## Project local Roll's config directory. This will be either `.roll/`
    ## or `.config/roll/`.
    #def local_directory
    #  @local_directory ||= (
    #    Dir['{.roll,.config/roll'].first || '.roll'
    #  )
    #end

    #
    def home_settings_directory
      @home_settings_directory ||= File.join(home_directory,  'settings')
    end

    # Environment home directory.
    def home_environment_directory
      @home_environment_directory ||= home_directory
    end
 
    ## Project local environments directory.
    #def local_environment_directory
    #  @local_environment_directory ||= (
    #    File.join(local_directory) #, 'environments')  # TODO: keep environments?
    #  )
    #end

    # Returns the name of the current environment.
    ##def current_environment
    #  ENV['roll_environment'] || ENV['RUBYENV'] || default_environment
    #end

    # List of local environments.
    #def local_environments
    #  Dir[File.join(local_environment_directory, '*')].map do |file|
    #    File.basename(file)
    #  end
    #end

    # List of home environment names.
    def home_environments
      Dir[File.join(home_environment_directory, '*')].map do |file|
        File.file?(file) ? File.basename(file) : nil
      end.compact
    end

    #
    def system_environments
      environments - home_environments
    end

    # List of all available user environments.
    def environments
      list = XDG.search_config('roll/*').map do |file|
        File.file?(file) ? File.basename(file) : nil
      end.compact
    end

    #--
    # List of all available environments.
    # TODO: Add system wide environments.
    #def environments
    #  #local_environments + home_environments # + system_environments
    #  home_environments # + system_environments
    #  #Dir[File.join('{'+DIRS.join(',')+'}', '*')].map do |file|
    #  #  File.basename(file)
    #  #end
    #end
    #++

    # TODO: Add system wide locations.
    def find_environment_file(name)
      dirs = [local_environment_directory, home_environment_directory]
      dirs.find do |dir|
        file = File.join(dir, name)
        return file if File.file?(file)
        return file+'.roll' if File.file?(file+'.roll')
      end
      return nil
    end

    # Default gem home directory path.
    def gem_home
      if defined? RUBY_FRAMEWORK_VERSION then
        File.join File.dirname(CONFIG["sitedir"]), 'Gems', CONFIG["ruby_version"]
      elsif CONFIG["rubylibprefix"] then
        File.join(CONFIG["rubylibprefix"], 'gems', CONFIG["ruby_version"])
      else
        File.join(CONFIG["libdir"], ruby_engine, 'gems', CONFIG["ruby_version"])
      end
    end

    # A wrapper around RUBY_ENGINE const that may not be defined.
    def ruby_engine
      if defined? RUBY_ENGINE then
        RUBY_ENGINE
      else
        'ruby'
      end
    end

  end

end
