#require File.dirname(__FILE__) + '/config.rb'
require 'roll/config'

require 'yaml'
require 'fileutils'

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
    DIRS = ::Config.find_config('roll', 'environments')

    #
    HOME_ENV_DIR = File.join(::Config::CONFIG_HOME, 'roll', 'environments')

    # File that stores the name of the current environment.
    CURRENT_FILE = File.join(::Config::CONFIG_HOME, 'roll', 'current')

    # Current environment name.
    def self.current
      @current ||= (
        if File.exist?(CURRENT_FILE)
          env = File.read(CURRENT_FILE).strip
        else
          env = ENV['RUBYENV'] || DEFAULT
        end
        #warn "#{env} is not a valid environment" unless list.include?(env)
        env
      )
    end

    # List of available environments.
    def self.list
      Dir[File.join('{'+DIRS.join(',')+'}', '*')].map do |file|
        File.basename(file)
      end
    end

    # Change environment to given +name+.
    #
    # TODO: should only last a long as the shell session,
    # not change it perminently.
    #
    def self.save(name)
      if name == 'system'
        FileUtils.rm(CURRENT_FILE)
      else
        File.open(CURRENT_FILE,'w'){|f| f << name.to_s}
      end
      CURRENT_FILE
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
    def each(&block)
      index.each(&block)
    end

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
        @file ||= ::Config.find_config('roll', 'environments', name, 'index').first
      end

      # Load the environment file.
      def reload
        if file && File.exist?(file)
          File.readlines(file).each do |line|
            line = line.strip
            next if line.empty?
            name, path, *loadpath = *line.split(/\s+/)
            @table[name.strip] << [path.strip, loadpath]
          end
        end
      end

      #
      def reset(index)
        @table = index
      end

      #
      def [](name)
        @table[name.to_s]
      end

      #
      def key?(name)
        @table.key?(name.to_s)
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

      #
      def to_s
        out = []
        max = @table.map{ |name, paths| name.size }.max
        @table.map do |name, paths|
          paths.each do |path, loadpath|
            out << ("%-#{max}s %s" % [name, path]) + ' ' + loadpath.join(' ')
          end
        end
        out.sort.reverse.join("\n")
      end

      # Save environment file.
      def save
        out = to_s
        #max = @table.map{ |name, paths| name.size }.max
        #@table.map do |name, paths|
        #  paths.each do |path|
        #    out << "%-#{max}s %s\n" % [name, path]
        #  end
        #end
        file = File.join(HOME_ENV_DIR, name, 'index')
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
        @file = file
      end

      # Get library version.
      # TODO: handle VERSION file
      #def load_version(path)
      #  file = Dir[File.join(path, '{,.}meta', 'version')].first
      #  if file
      #    File.read(file).strip  # TODO: handle YAML ?
      #  end
      #end
    end

    # The Lookup class provides a table of paths which
    # make it easy to quickly populate and refresh the
    # environment index.
    #
    # TODO: Provide a way to specifically exclude a location.
    # Probaby recognize a path with a '-' prefix.
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
        @file ||= ::Config.find_config('roll', 'environments', name, 'lookup').first
      end

      #
      def reload
        t = []
        if file && File.exist?(file)
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
        file = File.join(HOME_ENV_DIR, name, 'lookup')
        out = @table.map do |(path, depth)|
          "#{path}   #{depth}"
        end.sort
        dir = File.dirname(file)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        File.open(file, 'w') do |f|
          f <<  out.join("\n")
        end
        @file = file
      end

      # Generate index from lookup list.
      def index
        set = Hash.new{|h,k| h[k]=[]}
        locate.each do |path|
          name, loadpath = libdata(path)
          next if name == 'roll' # NEVER INCLUDE ROLL ITSELF!!!
          #vers = load_version(path)
          if name #&& vers
            set[name] << [path, loadpath]
          else
            warn "omitting: #{path}"
          end
        end
        set
      end

      # Locate projects.
      def locate
        locs = []
        each do |dir, depth|
          locs << find_projects(dir, depth)
        end
        locs.flatten
      end

      # Search a given directory for projects upto a given depth. Projects
      # directories are determined by containing a .ruby directory or a
      # lib directory.
      # 
      # NOTE: relying on lib/ is not a reliable as would be prefered.
      # I am hoping that .ruby/ directory will eventually become a 
      # standard.
      def find_projects(dir, depth=3)
        depth = Integer(depth || 3)
        depth = (0...depth).map{ |i| (["*"] * i).join('/') }.join(',')

        libs = []

        find = File.join(dir, "{#{depth}}", ".ruby/")
        dirs = Dir.glob(find)
        libs += dirs.map{|d| File.dirname(d) }.uniq

        #find = File.join(dir, "{#{depth}}", "lib/*.rb")
        #locals = Dir.glob(find)
        #locals.concat(locals.map{|d| File.dirname(File.dirname(d)) }.uniq)

        find = File.join(dir, "{#{depth}}", "lib/")
        dirs = Dir.glob(find)
        libs += dirs.map{|d| File.dirname(d) }.uniq

        libs.uniq
      end

      #
      def metadata(path)
        @metadata ||= {}
        @metadata[path] ||= Metadata.new(path)
      end

      #
      def libdata(path)
        data = metadata(path)

        if !dot_ruby?(path)
          name     = data.extended_metadata.name
          version  = data.extended_metadata.version
          loadpath = data.extended_metadata.loadpath || ['lib']

          dot_ruby!(path, name, version, loadpath)

          #if gemspec?(path)
          #  name, version, loadpath = geminfo(path)
          #  dot_ruby!(path, name, version, loadpath)
          #  #fakegem = FakeGem.load(specfile)
          #  #return fakegem.name, fakegem.require_paths  #fakegem.version
          #  return name, loadpath #, version ?
          #elsif pom?(path)
          #  data.dot_ruby! unless data.dot_ruby?
          #else
          #end
        else
          name     = data.name
          version  = data.version
          loadpath = data.loadpath
        end

        return name, loadpath
      end

      #
      def dot_ruby?(location)
        dir = File.join(location, '.ruby')
        return false unless File.directory?(dir)
        return true
      end

      #
      def dot_ruby!(location, name, version, loadpath)
        require 'fileutils'
        dir = File.join(location, '.ruby')
        FileUtils.mkdir(dir)
        File.open(File.join(dir, 'name'), 'w'){ |f| f << name }
        File.open(File.join(dir, 'version'), 'w'){ |f| f << version.to_s }
        File.open(File.join(dir, 'loadpath'), 'w'){ |f| f << loadpath.join("\n") }
      end

      ## Get library name.
      #def load_name(path)
      #  file = Dir[File.join(path, '{,.}meta', 'name')].first
      #  if file
      #    File.read(file).strip  # TODO: handle YAML
      #  end
      #end

    end#class Lookup

  end#class Environment

end

