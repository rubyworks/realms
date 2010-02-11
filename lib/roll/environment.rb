require 'yaml'
require 'fileutils'
#require 'roll/xdg'
require 'roll/config'

module Roll

  # An Environment represents a set of libraries.
  #
  class Environment

    # Default environment name.
    DEFAULT = 'production'  # 'local' ?

    # Location of environment files.
    #--
    # Perhaps combine all enrtries instead?
    #++
    DIR = ::Config.find_config('roll').first
    #DIR = XDG.config_home, 'roll', 'index'

    # Current environment name.
    def self.current
      ENV['RUBYENV'] || DEFAULT
    end

    # List of available environments.
    def self.list
      Dir[File.join(DIR, '*')].map do |file|
        File.basename(file)
      end
    end

    # Environment name.
    attr :name

    # Instantiate environment.
    def initialize(name=nil)
      @name = name || Environment.current
    end

    #
    def index
      @index ||= Index.new(name)
    end

    #
    def lookup
      @lookup ||= Lookup.new(name)
    end

    # Synchronize index to lookup table.
    def sync
      index.reset(lookup.index)
    end

    # Save index.
    def save
      index.save
    end

    #
    def each(&block) ; index.each(&block) ; end

    #
    def size ; index.size ; end

    #
    def to_s
      str = ""
      lookup.each do |(path, depth)|
        str << "#{path}  #{depth}\n"
      end
      str
    end


    # Index tracks the name and location of each library
    # in an environment.
    #--
    # TODO: Using a hash table means un-order, fix?
    #++
    class Index
      include Enumerable

      # Instantiate environment.
      def initialize(name=nil)
        @name  = name || Environment.current
        @table = Hash.new{ |h,k| h[k] = [] }
        reload
      end

      # Current ledger name.
      def name
        @name
      end

      # Environment file (full-path).
      def file
        @file ||= File.join(DIR, name, 'index')
      end

      # Load the environment file.
      def reload
        File.readlines(file).each do |line|
          line = line.strip
          next if line.empty?
          name, path = *line.split(/\s+/)
          @table[name.strip] << path.strip
        end
      end

      #
      def reset(index)
        @table = index
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
        out = ""
        max = @table.map{ |name, paths| name.size }.max
        @table.map do |name, paths|
          paths.each do |path|
            out << "%-#{max}s %s\n" % [name, path]
          end
        end
        if File.exist?(file)
          data = File.read(file)
          if out != data
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

    # The Lookup class provides a table of paths which
    # make it easy to quickly populate and refresh the
    # environment index.

    class Lookup
      include Enumerable

      #
      #DIR = ::Config.find_config('roll').first

      #
      def initialize(name=nil)
        @name = name || Environment.current
        reload
      end

      #
      def name
        @name
      end

      #
      def file
        @file ||= File.join(DIR, name, 'lookup')
      end

      #
      def reload
        t = []
        if File.exist?(file)
          lines = File.readlines(file)
          lines.each do |line|
            line = line.strip
            path, depth = *line.split(/\s+/)
            next if line =~ /^\s*$/  # blank
            next if line =~ /^\#/    # comment
            dir, depth = *line.split(/\s+/)
            t << [path, (depth || 3).to_i]
          end
        else
          t = []
        end
        @table = t
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
      def append(path, depth=3)
        path  = File.expand_path(path)
        depth = (depth || 3).to_i
        @table = @table.reject{ |(p, d)| path == p }
        @table.push([path, depth])
      end

      #
      def delete(path)
        @table.reject!{ |p,d| path == p }
      end

      #
      def save
        out = @table.map do |(path, depth)|
          "#{path}   #{depth}"
        end
        dir = File.dirname(file)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        File.open(file, 'w') do |f|
          f <<  out.join("\n")
        end
      end

      # Generate index from lookup list.
      def index
        set = Hash.new{ |h,k| h[k] = [] }
        locate.each do |path|
          name = load_name(path)
          #vers = load_version(path)
          if name #&& vers
            set[name] << path
          end
        end
        set
      end

      #
      def locate
        locs = []
        each do |dir, depth|
          locs << find_projects(dir, depth)
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

    end#class Lookup

  end#class Environment

end

