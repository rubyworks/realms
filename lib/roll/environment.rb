require 'time'
require 'roll/core_ext/rbconfig'
require 'roll/core_ext/hash'
require 'roll/xdg'

class Library

  # An ... represents a set of libraries to be served by Rolls.
  #
  class Environment

    include Enumerable

    # Instantiate environment given +name+ or file.
    def initialize(file=nil)
      @file = File.expand_path(file || Environment.file)
      @name = File.basename(@file).chomp('.roll')

      @lookup   = []
      @index    = [] #Hash.new{ |h,k| h[k] = [] }
      @metadata = {}

      load
    end

    # Environment file.
    attr :file

    # TODO: rename to label ?
    attr :name

    # Lookup is an Array of directory paths or globs.
    #
    # @return [Array] directory names or globs
    attr :lookup

    # Project index is a Hash.
    # The index is generated via #sync based on the `lookup` table.
    attr :index

    # Synchronize index to lookup table.
    def sync
      @index = lookup_index
    end

    ## Environment file (full-path).
    #def file
    #  @file ||= (
    #    Library.config.find_environment_file(name) || default_file
    #  )
    #end

    # TODO: Use array instead of Hash to store cache so it will be faster.
    # TODO: Use simple File read and write instead of Marshal for more speed.
    def load
      return unless File.exist?(file)
      #require_without_rolls 'yaml'
      #data = YAML.load(File.new(file))
      @lookup = []
      @index  = []

      ::File.readlines(file).each do |line|
        line = line.strip
        next if line.empty?
        next if line =~ /^#/
        @lookup << line
      end

      if ::File.exist?(file + '.cache')
        begin
          @index = Marshal.load(File.new(file + '.cache'))
        rescue TypeError => error
          warn error.message
          lookup_index
        end
        #::File.readlines(file + '.cache').each do |line|
        #  line = line.strip
        #  next if line.empty?
        #  next if line =~ /^#/
        #  row = line.split(',')
        #  @index << {
        #    :name     => row[0],
        #    :version  => Version.new(row[1]),
        #    :date     => normalize_date(row[2]),
        #    :location => row[3],
        #    :loadpath => row[4].split(':')
        #  }
        #end
      else
        lookup_index
      end
    end

    #
    def normalize_date(date)
      date = date.to_s.strip
      case date
      when ""
        Time.new
      else
        Time.parse(date)
      end
    end

=begin
    # Save environment file.
    def save
      require 'fileutils'
      out  = {:lookup=>lookup, :index=>index}.inspect #.to_yaml
      file = ::File.join(self.class.home, name)
      if ::File.exist?(file)
        old = File.read(file)
        return false if out == old
      else
        dir = File.dirname(file)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
      end
      ::File.open(file, 'w'){ |f| f << out }
      @file = file
    end
=end

    # Save environment cache file.
    def save
      require 'fileutils'
      dump = Marshal.dump(index)
      file = ::File.join(self.class.home, name + '.cache')
      dir  = ::File.dirname(file)
      ::FileUtils.mkdir_p(dir) unless File.exist?(dir)
      File.open(file, 'w') do |writer|
        writer << dump
      end
      @file = file
    end

    # Save environment file.
    def save_lookup
      require 'fileutils'
      file = ::File.join(self.class.home, name)
      dir  = ::File.dirname(file)
      ::FileUtils.mkdir_p(dir) unless File.exist?(dir)
      File.open(file, 'w') do |writer|
        writer << lookup.join("\n")
      end
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
      index = []
      lookup.each do |glob|  # dev?
        locations = find_projects(glob)
        locations.each do |location|
          data = metadata(location).to_h
          name = data[:name]
          name = nil if name && name.empty?
          next if name == 'roll' # do not include roll itself!
          if name #&& vers
            #data[:development] = !!dev  # TODO: what does dev do again?
            index << data
          else
            warn "roll: invalid .ruby file, omitting -- #{location}"
          end
        end
      end
      index
    end

    # Loop through the lookup paths and locate all projects within
    # them. Projects are identified by having .ruby/ entries,
    # or being an installed gem.
    def locate
      lookup.map{ |dir_or_glob| # dev?
        find_projects(dir_or_glob)
      }.flatten
    end

    # Search a given directory for projects upto a given depth. Projects
    # directories are determined by containing a .ruby directory or being
    # a rubygems location.
    #
    # Even though Rolls can locate gems, adding a set of .ruby entries
    # to you project is adventageous as it allows Rolls operate faster.
    def find_projects(dir_or_glob)
      #depth = Integer(depth || 3)
      libs = []
      #(0..depth).each do |i|
      #  star   = ::File.join(dir, *(['*'] * i))
      search = ::Dir.glob(dir_or_glob)
      search.each do |path|
        if dotruby?(path)
          libs << path
        elsif gemspec?(path)
          libs << path
        end
      end
      libs.uniq
    end

    # Return Metadata for given +location+. The Metadata object
    # is cached based on the +location+.
    def metadata(location)
      @metadata[location] ||= Metadata.new(location)
    end

    # Iterate over the index.
    def each(&block)
      index.each(&block)
    end

    # Size of the index.
    def size ; index.size ; end

    # Append an entry to the lookup list.
    def append(path, depth=3, live=false)
      path  = ::File.expand_path(path)
      depth = (depth || 3).to_i
      @lookup = @lookup.reject{ |(p, d)| path == p }
      @lookup.push([path, depth, !!live])
    end

    # Remove an entry from lookup list.
    def delete(path)
      @lookup.reject!{ |p,d| path == p }
    end

    # Returns name and loadpath of project at +location+.
    #def libdata(location)
    #  data = 
    #  name     = data.name
    #  version  = data.version
    #  loadpath = data.loadpath
    #  return name, loadpath
    #end

    # Does this location have .ruby/ entries?
    # TODO: Really is should at probably have a `version` too.
    def dotruby?(location)
      file = ::File.join(location, '.ruby')
      return false unless File.file?(file)
      return true
    end

    # Is this location a gem home location?
    def gemspec?(location)
      #return true if Dir[File.join(location, '*.gemspec')].first
      pkgname = ::File.basename(location)
      gemsdir = ::File.dirname(location)
      specdir = ::File.join(File.dirname(gemsdir), 'specifications')
      gemspec = ::Dir[::File.join(specdir, "#{pkgname}.gemspec")].first
    end

    # Does the environment include any entires that lie within the *current*
    # gem directory?
    def has_gems?
      dir = (ENV['GEM_HOME'] || ::Config.gem_home)
      rex = ::Regexp.new("^#{Regexp.escape(dir)}\/")
      return true if lookup.any? do |(path, depth)|
        rex =~ path
      end
      return true if index.any? do |name, vers|
        vers.any? do |path, loadpath|
          rex =~ path
        end
      end
      return false
    end

    #
    def inspect
      "#<#{self.class}:#{object_id} #{name} (#{size} libraries)>"
    end

    # Returns a string representation of lookup and index
    # exactly as it is stored in the environment file.
    def to_s
      out = ''
      out << "#{name} "
      out << "(%s libraries)\n" % [index.size]
      out << "\nLookup:\n"
      out << to_s_lookup
      out << "\n"
      out << "(file://#{file})"
      out
    end

    # Returns a String of lookup paths and depths, one on each line.
    def to_s_lookup
      str = ""
      max = lookup.map{ |path| path.size }.max
      lookup.each do |path|
        str << ("  - %-#{max}s \n" % [path]) #, dev ? '(development)' : ''])
      end
      str
    end

    # Returns a string representation of lookup and index
    # exactly as it is stored in the environment file.
    def to_s_index
      max  = ::Hash.new{|h,k| h[k]=0 }
      list = index.dup

      list.each do |data|
        data[:loadpath] = data[:loadpath].join(' ')
        data[:date]     = iso(data[:date])
        data.each do |k,v|
          max[k] = v.to_s.size if v.to_s.size > max[k]
        end
      end

      max = max.values_at(:name, :version, :date, :location, :loadpath)

      list = list.map do |data|
        data.values_at(:name, :version, :date, :location, :loadpath)
      end

      list.sort! do |a,b|
        x = a[0] <=> b[0]
        x != 0 ? x : b[1] <=> a[1]  # TODO: use natcmp
      end
 
      mask = max.map{ |size| "%-#{size}s" }.join('  ') + "\n"

      out = ''
      list.each do |name, vers, date, locs, lpath|
        str = mask % [name, vers, date, locs, lpath]
        out << str 
      end
      out
    end

    #
    def iso(date)
      case date
      when ::Time
        date.strftime("%Y-%m-%d")
      else
        date.to_s
      end
    end

    # Make sure each project location in the index has .ruby entries.
    # If it does not have .ruby entries then it will attempt to create
    # them.
    #
    # TODO: Rename this method.
    #def prep
    #  locate.each do |path|
    #    dotruby_ensure(path)
    #  end
    #  report_dotruby_write_errors
    #end

    # Ensure a project +location+ has .ruby entries.
    #def dotruby_ensure(location)
    #  data = metadata(location)
    #  begin
    #    success = data.dotruby_ensure
    #  rescue Errno::EACCES
    #    success = false
    #    dotruby_write_errors << location
    #  end
    #  if !success
    #    # any other way to do it?
    #    dotruby_missing_errors << location
    #  end     
    #  success
    #end

    # Stores a list of write errors from attempts to auto-create .ruby entries.
    #def dotruby_write_errors
    #  @dotruby_write_errors ||= []
    #end

    #
    #def dotruby_missing_errors
    #  @dotruby_missing_errors ||= []
    #end

    # Output to STDERR the list of projects that failed to allow .ruby entries.
    #def report_dotruby_write_errors
    #  return if dotruby_write_errors.empty? 
    #  $stderr.puts "Rolls attempted to write .ruby/ entries into each of the following:"
    #  $stderr.puts
    #  $stderr.puts "  " + dotruby_write_errors.join("\n  ")
    #  $stderr.puts
    #  $stderr.puts "but permission to do so was denied. Rolls needs these entries"
    #  $stderr.puts "to operate at peak performance. Please grant it permission"
    #  $stderr.puts "(e.g. sudo), or add the entries manually. These libraries cannot"
    #  $stderr.puts "be served by Rolls until this is done. You might want to encourage"
    #  $stderr.puts "the package maintainer to include .ruby/ entries in the distribution."
    #  $stderr.puts
    #end

    class << self

      # Location of environment files. This includes user location, but also
      # read-only sytems-wide locations, should an administratore want to set
      # any of those up.
      #DIRS = ::Config.find_config('roll', 'environments')

      # Roll's user home temporary cache directory.
      #ROLL_CACHE_HOME = File.join(xdg_cache_home, 'roll')

      # Roll's user home configuration directory.
      #ROLL_CONFIG_HOME = File.join(xdg_config_home, 'roll')

      # Default environment name.
      DEFAULT_ENVIRONMENT = 'production' # 'master' ?

      # Project local environments directory.
      #def local
      #  Library.config.local_environment_directory
      #end

      # Default environment name.
      def default
        #Library.config.default_environment
        'master'
      end

      # Returns the current environment file.
      def file
        if roll_file
          roll_file
        elsif roll_name
          File.join(home, roll_name)
        else
          File.join(home, default)
        end
      end

      # Returns the <i>calling name</i> of the current environment.
      # TODO: rename this method to #label ?
      def name
        #Library.config.current_environment
        File.basename(file).chomp('.roll')
      end

      # Current roll file as designated in environment variables.
      # If `roll_file` is set it takes precedence over `roll_name`.
      def roll_file
        config.roll_file
      end

      # Current roll name as designated in environment variables.
      def roll_name
        config.roll_name
      end

      # Returns the name of the current environment.
      # TODO: change this to return the actual environment object.
      def current
        #Library.config.current_environment
        file
      end

      # List of environments defined in standard config locations.
      def list
        Library.config.environments
      end

      #
      def config
        Library.config
      end

      # Lookup environment.
      #--
      # TODO: Why is $LOAD_GROUP set here?
      #++
      def [](name)
        if name
          Environment.new(name)
        else
          $LOAD_GROUP ||= Environment.new #(name)
        end
      end

      # Environment home directory.
      def home
        config.home_environment_directory
      end

    end

    class << self

      # Synchronize an environment by +name+. If a +name+
      # is not given the current environment is synchronized.
      def sync(name=nil)
        env = new(name)
        env.sync
        env.save
      end

      # Check to see if an environment is in-sync by +name+. If a +name+
      # is not given the current environment is checked.
      def check(name=nil)
        env = new(name)
        env.index == env.lookup_index
      end

      # Add path to current environment.
      def insert(path, depth=3, live=false)
        env = new
        env.append(path, depth, live)
        env.sync
        env.save
        return path, env.file
      end

      # Alias for #insert.
      #alias_method :in, :insert

      # Remove path from current environment.
      def remove(path)
        env = new
        env.delete(path)
        env.sync
        env.save
        return path, env.file
      end

      # Alias for #remove.
      #alias_method :out, :remove

      # Go thru each roll lib and collect bin paths.
      def path
        binpaths = []
        list.each do |name|
          lib = library(name)
          if lib.bindir?
            binpaths << lib.bindir
          end
        end
        binpaths
      end

      # Verify dependencies are in current environment.
      #--
      # TODO: Instead of Dir.pwd, lookup project root.
      #++
      def verify(name=nil)
        if name
          open(name).verify
        else
          Library.new(Dir.pwd).verify
        end
      end

      # Sync environments that contain locations relative to the
      # current gem home.
      def sync_gem_environments
        resync = []
        environments.each do |name|
          env = environment(name)
          if env.has_gems?         
            resync << name
            env.sync
            env.save
          end
        end
        resync
      end

    end

  end

end
