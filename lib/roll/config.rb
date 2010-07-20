require 'roll/core_ext/rbconfig'

class Library

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
    #ROLL_CACHE_HOME = File.join(xdg_cache_home, 'roll')

    # Roll's user home configuration directory.
    #ROLL_CONFIG_HOME = File.join(xdg_config_home, 'roll')

    # Default environment name.
    DEFAULT_ENVIRONMENT = 'production'

    #
    def initialize()
    end

    # Roll's home configuration directory.
    def home_directory
      File.join(XDG.config_home, 'roll')
    end

    # Roll's cache directory.
    def cache_directory
      File.join(XDG.cache_home, 'roll')
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

    module XDG
      extend self

      # User's home directory.
      def home
        File.expand_path('~') # ENV['HOME']
      end

      # Freedesktop.org standard location for configuration files.
      def config_home
        File.expand_path(ENV['XDG_CONFIG_HOME'] || File.join(home, '.config'))
      end

      # Location of user's personal config directory.
      def data_home
        File.expand_path(ENV['XDG_DATA_HOME'] || File.join(home, '.local', 'share'))
      end

      # Freedesktop.org standard location for temporary cache.
      def cache_home
        File.expand_path(ENV['XDG_CACHE_HOME'] || File.join(home, '.cache'))
      end

      # List of system config directories.
      def config_dirs
        dirs = ENV['XDG_CONFIG_DIRS'].to_s.split(/[:;]/)
        if dirs.empty?
          dirs = [File.join(::RbConfig::CONFIG['sysconfdir'], 'xdg')]
        end
        dirs.collect{ |d| File.expand_path(d) }
      end

      # List of system data directories.
      def data_dirs
        dirs = ENV['XDG_DATA_DIRS'].to_s.split(/[:;]/)
        if dirs.empty?
          dirs = [::RbConfig::CONFIG['datarootdir']]  # what about local?
        end
        dirs.collect{ |d| File.expand_path(d) }
      end

      # Lookup configuration file.
      def search_config(*glob)
        flag = 0
        flag = (flag | glob.pop) while Fixnum === glob.last
        find = []
        [config_home, *config_dirs].each do |dir|
          path = File.join(dir, *glob)
          if block_given?
            find.concat(Dir.glob(path, flag).select(&block))
          else
            find.concat(Dir.glob(path, flag))
          end
        end
        find
      end

      # Lookup data file.
      def search_data(*glob)
        flag = 0
        flag = (flag | glob.pop) while Fixnum === glob.last
        find = []
        [data_home, *data_dirs].each do |dir|
          path = File.join(dir, *glob)
          if block_given?
            find.concat(Dir.glob(path, flag).select(&block))
          else
            find.concat(Dir.glob(path, flag))
          end
        end
        find
      end
    end

  end

end

