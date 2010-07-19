require 'roll/xdg'

module Roll

  # 
  def self.config
    @config ||= Config.new
  end

  # Rolls Configuration.
  class Config

    # Location of environment files. This includes user location, but also
    # read-only sytems-wide locations, should an administratore want to set
    # any of those up.
    #DIRS = ::Config.find_config('roll', 'environments')

    # Roll's user home temporary cache directory.
    ROLL_CACHE_HOME = File.join(XDG.cache_home, 'roll')

    # Roll's user home configuration directory.
    ROLL_CONFIG_HOME = File.join(XDG.config_home, 'roll')

    # Default environment name.
    DEFAULT_ENVIRONMENT = 'production'

    #
    def initialize()
    end

    # Roll's use home configuration directory.
    def home_directory
      ROLL_CONFIG_HOME
    end

    # Project local Roll's config directory. This will be either `.roll/`
    # or `.config/roll/`.
    def local_directory
      @local_directory ||= (
        Dir['{.roll,.config/roll}'].first || '.config/roll'
      )
    end

    #
    def home_settings_directory
      @home_settings_directory ||= File.join(home_directory,  'settings')
    end

    # Environment home directory.
    def home_environment_directory
      @home_environment_directory ||= File.join(home_directory, 'environments')
    end
 
    # Project local environments directory.
    def local_environment_directory
      @local_environment_directory ||= (
        File.join(local_directory, 'environments')
      )
    end

    # Default environment name, looks for default_environment setting,
    # otherwise usesDEFAULT_ENVIRONMENT constant, which is 'production'.
    # If no current environment variable is set, this value will be used.
    def default_environment
      @default_environment ||= get('default_environment', DEFAULT_ENVIRONMENT)
    end

    # Returns the name of the current environment. If `auto_isolate` is set,
    # then returns the `local` environment if it exists.
    def current_environment
      if auto_isolate?
        name = ["local.#{RUBY_PLATFORM}", 'local'].find do |name|
          find_environment_file(name)
        end
        return name if name
      end
      ENV['roll_environment'] || ENV['RUBYENV'] || default_environment
    end

    # Automatically use isolated environment if present?
    def auto_isolate?
      get(:auto_isolate)
    end

    # List of local environments.
    def local_environments
      Dir[File.join(local_environment_directory, '*')].map do |file|
        File.basename(file)
      end
    end

    # List of home environments.
    def home_environments
      Dir[File.join(home_environment_directory, '*')].map do |file|
        File.basename(file)
      end
    end

    #
    def system_environments
      environments - home_environments
    end

    # List of all available environments.
    def environments
      XDG.search_config('roll/environments/*').map do |file|
        File.basename(file)
      end
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
      end
      return nil
    end

    # Get a setting's value. A setting is read either from the user's
    # home settings files or from the environment variable.
    def get(name, fallback=nil)
      name = name.to_s.downcase
      file = File.join(home_settings_directory, name)
      if File.file?(file)
        val = File.read(file).strip
        val = nil if val.empty?
      else
        val = ENV["roll_#{name}"]
      end
      val ? val : fallback
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

