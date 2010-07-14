require 'roll/config'

module Roll

  # An Environment represents a set of libraries to be served by Rolls.
  #
  # TODO: Rename this to Ledger?
  class Environment

    # Location of environment files.
    DIRS = ::Config.find_config('roll', 'environments')

    #
    HOME_ENV_DIR = File.join(::Config::CONFIG_HOME, 'roll', 'environments')

    # If no default environment variable is set, the content of this
    # file will be used.
    DEFAULT_FILE = File.join(::Config::CONFIG_HOME, 'roll', 'default')

    # Default environment name.
    DEFAULT = File.exist?(DEFAULT_FILE) ? File.read(DEFAULT_FILE).strip : 'production'

    # File that stores the name of the current environment during
    # the current Ruby session.
    PID_FILE = File.join(::Config::CACHE_HOME, 'roll', Process.ppid.to_s)

    # Returns the name of the current environment.
    def self.current
      @current ||= (
        if File.exist?(PID_FILE)
          File.read(PID_FILE).strip
        else
          ENV['RUBYENV'] || DEFAULT
        end
      )
    end

    # Change environment to given +name+.
    #
    # This only lasts a long as the parent session. It tracks the session
    # via a temporary file in `$HOME/.cache/roll/<ppid>`.
    def self.use(name)
      require 'fileutils'
      dir = File.dirname(PID_FILE)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      File.open(PID_FILE, 'w'){ |f| f << name }
      PID_FILE
    end

    # List of available environments.
    def self.list
      Dir[File.join('{'+DIRS.join(',')+'}', '*')].map do |file|
        File.basename(file)
      end
    end

    # Environment name.
    attr :name

    # Instantiate environment.
    def initialize(name=nil)
      @name = name || Environment.current
      @lookup = []
      @index  = Hash.new{ |h,k| h[k] = [] }
      load
    end

    # Project index is a Hash of `name => [location, loadpath]`.
    def index
      @index #||= Index.new(name)
    end

    # Lookup is an Array of `[path, depth]`.
    def lookup
      @lookup #||= Lookup.new(name)
    end

    # Synchronize index to lookup table.
    def sync
      @index = lookup_index
    end

    # Iterate over the index.
    def each(&block)
      index.each(&block)
    end

    # Size of the index.
    def size ; index.size ; end

    # Returns a string representation of lookup and index
    # exactly as it is stored in the environment file.
    def to_s
      set = []
      lookup.each do |(path, depth)|
        set << ['-', path, depth]
      end
      set << ['','','']
      index.each do |name, paths|
        paths.each do |path, loadpath|
          set << [name, path, loadpath.join(' ')]
        end
      end
      name_max = set.map{|name, path, rel| name.size }.max
      path_max = set.map{|name, path, rel| path.size }.max
      out = ''
      set.each do |name, path, rel|
        out << "%-#{name_max}s  %-#{path_max}s  %s\n" % [name, path, rel]
      end
      out
    end

    # Returns a String of lookup paths and depths, one on each line.
    def to_s_lookup
      str = ""
      lookup.each do |(path, depth)|
        str << "- #{path} #{depth}\n"
      end
      str
    end

    # Returns a String of `name location loadpaths`, one on each line.
    def to_s_index
      out = []
      max = index.map{ |name, paths| name.size }.max
      index.map do |name, paths|
        paths.each do |path, loadpath|
          out << ("%-#{max}s %s" % [name, path]) + ' ' + loadpath.join(' ')
        end
      end
      out.sort.reverse.join("\n")
    end

    # Append an entry to the lookup list.
    def append(path, depth=3)
      path  = File.expand_path(path)
      depth = (depth || 3).to_i
      @lookup = @lookup.reject{ |(p, d)| path == p }
      @lookup.push([path, depth])
    end

    # Remove an entry from lookup list.
    def delete(path)
      @lookup.reject!{ |p,d| path == p }
    end

    # Environment file (full-path).
    def file
      @file ||= ::Config.find_config('roll', 'environments', name).first
    end

    # Load the environment file.
    def load
      if file && File.exist?(file)
        lines = File.readlines(file).map{ |line| line.strip }
        lines = lines.reject{ |line| /^\#/ =~ line or /^$/ =~ line }
        lines.each do |line|
          name, path, *loadpath = *line.split(/\s+/)
          if name == '-'
            lookup << [path, (loadpath.first || 2).to_i]  # TODO: support multiple depths
          else
            index[name] << [path, loadpath]
          end
        end
      end
    end

    # Save environment file.
    def save
      require 'fileutils'

      out = to_s

      file = File.join(HOME_ENV_DIR, name)
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

    # Create a new environment +new_name+ with the contents
    # of the current enviroment.
    def copy(new_name)
      new_env = dup
      new_env.instance_eval do
        @name = new_name
        @file = nil
      end
      new_env
    end

    # Merge two environments. +Other+ can either be an Environment object
    # or the name of one.
    #
    # NOTE: It is probably best to re-sync the environment after this.
    def merge!(other)
      if !(Environment === other)
        other = Environment.new(other)  # self.class.new(other)
      end
      @lookup = lookup | other.lookup
      @index  = index.merge(other.index)
      self
    end

    # Generate index from lookup list.
    def lookup_index
      set = Hash.new{|h,k| h[k]=[]}
      locate.each do |path|
        name, loadpath = libdata(path)
        name = nil if name.empty?
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

    # Make sure each project location in the index has .ruby entries.
    # If it does not have .ruby entries then it will attempt to create
    # them.
    #
    # TODO: Rename this method.
    def prep
      locate.each do |path|
        dotruby_ensure(path)
      end
      report_dotruby_write_errors
    end

    # Loop through the lookup paths and locate all projects within
    # them. Projects are identified by having .ruby/ entries,
    # or being an installed gem.
    def locate
      @locate ||= lookup.map{|dir, depth| find_projects(dir,depth) }.flatten
    end

    # Search a given directory for projects upto a given depth. Projects
    # directories are determined by containing a .ruby directory or being
    # a rubygems location.
    #
    # Even though Rolls can locate gems, adding a set of .ruby entries
    # to you project is adventageous as it allows Rolls operate faster.
    def find_projects(dir, depth=3)
      depth = Integer(depth || 3)
      libs = []
      (0...depth).each do |i|
        star   = File.join(dir, *('*' * i))
        search = Dir.glob(star)
        search.each do |path|
          if dotruby?(path)
            libs << path
          elsif gemspec?(path)
            libs << path
          end
        end
      end
      libs.uniq
    end

    # Return Metadata for given +location+. The Metadata object
    # is cache based on the +location+.
    def metadata(location)
      @metadata ||= {}
      @metadata[location] ||= Metadata.new(location)
    end

    # Returns name and loadpath of project as +location+.
    def libdata(location)
      data = metadata(location)
      name     = data.name
      version  = data.version
      loadpath = data.loadpath
      return name, loadpath
    end

    # Ensure a project +location+ has .ruby entries.
    def dotruby_ensure(location)
      data = metadata(location)
      begin
        success = data.dotruby_ensure
      rescue Errno::EACCES
        success = false
        dotruby_write_errors << location
      end
      if !success
        # any other way to do it?
        dotruby_missing_errors << location
      end     
      success
    end

    # Stores a list of write errors from attempts to auto-create .ruby entries.
    def dotruby_write_errors
      @dotruby_write_errors ||= []
    end

    #
    def dotruby_missing_errors
      @dotruby_missing_errors ||= []
    end

    # Output to STDERR the list of projects that failed to allow .ruby entires.
    def report_dotruby_write_errors
      return if dotruby_write_errors.empty? 
      $stderr.puts "Rolls attempted to write .ruby/ entries into each of the following:"
      $stderr.puts
      $stderr.puts "  " + dotruby_write_errors.join("\n  ")
      $stderr.puts
      $stderr.puts "but permission to do so was denied. Rolls needs these entries"
      $stderr.puts "to operate at peak performance. Please grant it permission"
      $stderr.puts "(e.g. sudo), or add the entries manually. These libraries cannot"
      $stderr.puts "be served by Rolls until this is done. You might want to encourage"
      $stderr.puts "the package maintainer to include .ruby/ entries in the distribution."
      $stderr.puts
    end

    # Does this location have .ruby/ entries?
    # TODO: Really is should at least have a `name` entry and probably a `version`.
    def dotruby?(location)
      dir = File.join(location, '.ruby')
      return false unless File.directory?(dir)
      return true
    end

    # Is this location a gem location?
    def gemspec?(location)
      return true if Dir[File.join(location, '*.gemspec')].first

      pkgname = File.basename(location)
      gemsdir = File.dirname(location)
      specdir = File.join(File.dirname(gemsdir), 'specifications')
      return true if Dir[File.join(specdir, "#{pkgname}.gemspec")].first

      return false
    end

  end#class Environment

end

