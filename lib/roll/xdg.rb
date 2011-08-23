require 'roll/core_ext/rbconfig'

module Roll

  # XDG utility functions.
  #
  # @see http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
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
    #
    # @param glob [Array] look-up globs
    #
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


=begin
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
=end

