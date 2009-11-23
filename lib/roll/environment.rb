require 'yaml'
require 'fileutils'
require 'roll/xdg'

module Roll
  require 'roll/locals'

  #
  class Environment

    #
    DEFAULT = 'testing' #'production'

    #
    DIR = XDG.config_home, 'roll', 'index'

    #
    def self.current
      ENV['RUBYENV'] || DEFAULT
    end

    # List of available environments.
    def self.list
      Locals.list
    end

    #
    include Enumerable

    #
    def initialize(name=nil)
      @name = name || self.class.current
      reload
    end

    # Current ledger name.
    def name
      @name
    end

    #
    def file
      @file ||= File.join(DIR, name)
    end

    #
    def reload
      if File.exist?(file)
        @table = YAML.load(File.new(file))
      else
        @table = sync
        save
      end
    end

    #
    def each(&block)
      @table.each(&block)
    end

    #
    def size
      @table.size
    end

    #
    def to_h
      @table.dup
    end

    # Save ledger file.
    def save
      out = @table.to_yaml
      if File.exist?(file)
        if out != File.read(file)
          File.open(file, 'wb'){ |f| f << out }
        else
          puts "current: #{name}"
        end
      else
        dir = File.dirname(file)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        File.open(file, 'wb'){ |f| f << out }
      end
    end

    #
    def locals
      @locals ||= Locals.new(name)
    end

    #
    def sync
      list = Hash.new{ |h,k| h[k] = [] }
      sync_locations.each do |path|
        name = load_name(path)
        #h = {}
        #h['v'] = load_version(path)
        #h['r'] = load_released(path)
        #h['l'] = load_loadpath(path)
        #h['p'] = path
        if name #&& vers
          list[name] << path
        end
      end
      list
    end

    #
    def sync_locations
      locs = []
      if File.exist?(file)
        locals.each do |line, depth|
          locs << find_projects(dir, depth)
        end
      end
      locs.flatten
    end

    # Search a given directory for projects upto a given depth.
    # Projects directories are determined by containing a
    # 'meta' or '.meta' directory.
    def find_projects(dir, depth=3)
      depth = Integer(depth || 3)
      depth = (0...depth).map{ |i| (["*"] * i).join('/') }.join(',')
      glob = File.join(dir, "{#{depth}}", "{.meta,meta}")
      meta_locations = Dir[glob]
      meta_locations.map{ |d| d.chomp('/meta').chomp('/.meta') }
    end

    # Get library name.
    def load_name(path)
      file = Dir[File.join(path, '{,.}meta', 'name')].first
      if file
        File.read(file).strip  # TODO: handle YAML
      end
    end

=begin
    # Get library version.
    # TODO: handle VERSION file
    def load_version(path)
      file = Dir[File.join(path, '{,.}meta', 'version')].first
      if file
        File.read(file).strip  # TODO: handle YAML
      end
    end

    # Get release date.
    def load_released(path)
      file = Dir[File.join(path, '{,.}meta', 'released')].first
      if file
        File.read(file).strip  # TODO: handle YAML
      end
    end

    # Get loadpaths.
    def load_loadpath(path)
      file = Dir[File.join(path, '{,.}meta', 'loadpath')].first
      if file
        File.read(file).strip.split(/\s*\n/)  # TODO: handle YAML
      else
        []
      end
    end
=end

  end

end

