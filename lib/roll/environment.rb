require 'yaml'
require 'fileutils'
require 'roll/xdg'
require 'roll/locals'

module Roll

  # TODO: Using a hash table means un-order, fix?
  class Environment

    include Enumerable

    # Default environment name.
    DEFAULT = 'production'

    # Location of environment files.
    DIR = XDG.config_home, 'roll', 'index'

    # Current environment name.
    def self.current
      ENV['RUBYENV'] || DEFAULT
    end

    # List of available environments.
    def self.list
      Locals.list
    end

    # Instantiate environment.
    def initialize(name=nil)
      @name = name || self.class.current
      reload
    end

    # Current ledger name.
    def name
      @name
    end

    # Environment file (full-path).
    def file
      @file ||= File.join(DIR, name)
    end

    # Load the environment file.
    def reload
      if File.exist?(file)
        @table = YAML.load(File.new(file))
      else
        @table = sync
        save
      end
    end

    # Look through the environment table.
    def each(&block)
      @table.each(&block)
    end

    # Number of entries.
    def size
      @table.size
    end

    #
    def to_h
      @table.dup
    end

    # Save environment file.
    def save
      out = @table.to_yaml
      if File.exist?(file)
        yaml = YAML.load(File.new(file))
        if out != yaml
          File.open(file, 'w'){ |f| f << out }
          #puts "updated: #{name}"
          true
        else
          #puts "current: #{name}"
          false
        end
      else
        dir = File.dirname(file)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        File.open(file, 'w'){ |f| f << out }
        #puts "created: #{name}"
        true
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
        #vers = load_version(path)
        if name #&& vers
          list[name] << path
        end
      end
      @table = list
    end

    #
    def sync_locations
      locs = []
      #if File.exist?(file)
        locals.each do |dir, depth|
          locs << find_projects(dir, depth)
        end
      #end
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
        File.read(file).strip  # TODO: handle YAML ?
      end
    end
=end

  end

end

