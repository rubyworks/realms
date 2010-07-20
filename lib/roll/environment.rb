require 'roll/core_ext/hash'
require 'time'

class Library
  require 'roll/config'

  # An Environment represents a set of libraries to be served by Rolls.
  #
  class Environment
    include Enumerable

    # Environment name.
    attr :name

    # Instantiate environment.
    def initialize(name=nil)
      @name = name || Environment.current
      @lookup   = []
      @index    = [] #Hash.new{ |h,k| h[k] = [] }
      @metadata = {}
      load
    end

    # Lookup is an Array of `[path, depth]`.
    def lookup
      @lookup
    end

    # Project index is a Hash of `name => [location, loadpath]`.
    # The index is generated via #sync based on the `lookup` table.
    def index
      @index
    end

    # Synchronize index to lookup table.
    def sync
      if /^local(\.|$)/ =~ name    # preven locals from syncing
        # TODO: use isolate
      else
        @index = lookup_index
      end
    end

    # Environment file (full-path).
    def file
      @file ||= (
        Library.config.find_environment_file(name) || default_file
      )
    end

    #
    def default_file
      case name
      when /^local(\.|$)/
        ::File.join(self.class.local, name)
      else
        ::File.join(self.class.home, name)
      end
    end

    #
    def load
      return unless File.exist?(file)
      #require_without_rolls 'yaml'
      #data = YAML.load(File.new(file))
      @lookup = []
      @index  = []

      ::File.readlines(file).each do |line|
        row = line.strip.split(',')
        if row.first == '-'
          row.shift
          @lookup << row
        else
          @index << {
            :name     => row[0],
            :version  => Version.new(row[1]),
            :date     => ::Time.parse(row[2]),
            :location => row[3],
            :loadpath => row[4].split(':')
          }
        end
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

    # Save environment file.
    def save
      require 'fileutils'
      require 'csv'

      out = []

      lookup.each do |(path, depth, dev)|
        out << ["-", path, depth, dev, "-"]
      end

      index.each do |d|
        out << [d[:name], d[:version].to_s, iso(d[:date]), d[:location], d[:loadpath].join(':')]
      end

      file = ::File.join(self.class.home, name)
      dir  = ::File.dirname(file)
      ::FileUtils.mkdir_p(dir) unless File.exist?(dir)

      ::CSV.open(file, 'w') do |writer|
        out.each{ |a| writer << a }
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
      index = []
      lookup.each do |dir, depth, dev|
        locations = find_projects(dir,depth)
        locations.each do |location|
          data = metadata(location).to_h
          name = data[:name].strip
          name = nil if name.empty?
          next if name == 'roll' # do not include roll itself!
          if name #&& vers
            data[:development] = !!dev
            index << data
          else
            warn "roll: no .ruby/name, omitting -- #{location}"
          end
        end
      end
      index
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

    # Loop through the lookup paths and locate all projects within
    # them. Projects are identified by having .ruby/ entries,
    # or being an installed gem.
    def locate
      lookup.map{ |dir, depth, dev|
        find_projects(dir,depth)
      }.flatten
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
      (0..depth).each do |i|
        star   = ::File.join(dir, *(['*'] * i))
        search = ::Dir.glob(star)
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
      @metadata[location] ||= Metadata.new(location)
    end

    # Iterate over the index.
    def each(&block)
      index.each(&block)
    end

    # Size of the index.
    def size ; index.size ; end

    # Append an entry to the lookup list.
    def append(path, depth=3, development=false)
      path  = ::File.expand_path(path)
      depth = (depth || 3).to_i
      @lookup = @lookup.reject{ |(p, d)| path == p }
      @lookup.push([path, depth, !!development])
    end

    # Remove an entry from lookup list.
    def delete(path)
      @lookup.reject!{ |p,d| path == p }
    end

    # Returns name and loadpath of project as +location+.
    #def libdata(location)
    #  data = 
    #  name     = data.name
    #  version  = data.version
    #  loadpath = data.loadpath
    #  return name, loadpath
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

    # Output to STDERR the list of projects that failed to allow .ruby entires.
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

    # Does this location have .ruby/ entries?
    # TODO: Really is should at probably have a `version` too.
    def dotruby?(location)
      name_file = ::File.join(location, '.ruby', 'name')
      return false unless File.file?(name_file)
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
      max = lookup.map{ |(path, depth)| path.size }.max
      lookup.each do |(path, depth, dev)|
        str << ("  - %-#{max}s  %s  %s\n" % [path, depth.to_s, dev ? '(development)' : ''])
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


    # C L A S S  M E T H O D S

    # Environment home directory.
    def self.home
      Library.config.home_environment_directory
    end
 
    # Project local environments directory.
    def self.local
      Library.config.local_environment_directory
    end

    # Default environment name.
    def self.default
      Library.config.default_environment
    end

    # Returns the name of the current environment.
    def self.name
      Library.config.current_environment
    end

    # Returns the name of the current environment.
    # TODO: change this to return the actual environment.
    def self.current
      Library.config.current_environment
    end

    # List of names of available environments.
    def self.list
      Library.config.environments
    end

    #
    def self.[](name)
      if name
        Environment.new(name)
      else
        $LOAD_GROUP ||= Environment.new(name)
      end
    end

    # Synchronize an environment by +name+. If a +name+
    # is not given the current environment is synchronized.
    def self.sync(name=nil)
      env = new(name)
      env.sync
      env.save
    end

    # Check to see if an environment is in-sync by +name+. If a +name+
    # is not given the current environment is checked.
    def self.check(name=nil)
      env = new(name)
      env.index == env.lookup_index
    end

    # Add path to current environment.
    def self.insert(path, depth=3, dev=false)
      env = new
      env.append(path, depth, dev)
      env.sync
      env.save
      return path, env.file
    end

    # Alias for #insert.
    #alias_method :in, :insert

    # Remove path from current environment.
    def self.remove(path)
      env = new
      env.delete(path)
      env.sync
      env.save
      return path, env.file
    end

    # Alias for #remove.
    #alias_method :out, :remove

    # Go thru each roll lib and collect bin paths.
    def self.path
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
    def self.verify(name=nil)
      if name
        open(name).verify
      else
        Library.new(Dir.pwd).verify
      end
    end

    # Sync environments that contain locations relative to the
    # current gem home.
    def self.sync_gem_environments
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

  end#class Environment

end


=begin
    # Load the environment file.
    def load
      if file && ::File.exist?(file)
        lines = ::File.readlines(file).map{ |line| line.strip }
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
=end

