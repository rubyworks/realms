require 'fileutils'
require 'roll/xdg'

module Roll

  # = Environment
  #
  class Environment

    DEFAULT_ENVIRONMENT = "production"

    #
    def self.file
      File.join(XDG.config_home, "roll/environment")
    end

    #
    def self.current
      file = file()
      if File.exist?(file)
        File.read(file).strip
      else
        DEFAULT_ENVIRONMENT # ENV['ROLL_ENVIRONEMT']
      end
    end

    #
    def self.save(name)
      file = file()
      File.open(file, 'w'){ |f| f << "#{name}" }
      #ledger = File.join(XDG.config_home, "roll/environments/#{name}")
      #if !File.exist?(ledger)
      #  File.open(ledger, 'w'){ |f| f << "" }
      #end
    end

    #def environment_delete(name)
    #  raise "Can't delete default ledger." if DEFAULT_ENVIRONMENT == name
    #  File.open(environment_file, 'w'){ |f| f << DEFAULT_ENVIRONMENT }
    #  ledger = File.join(XDG.config_home, "roll/#{name}.ledger")
    #  if File.exist?(ledger)
    #    FileUtils.rm(ledger)
    #  end
    #end

    include Enumerable

    #
    attr :name

    #
    attr :file

    #
    attr :list

    #
    def initialize(name=nil)
      @name = (name ? name : self.class.current)
      @file = XDG.config_find("roll/environments/#{@name}")
      if @file
        read
      else
        @file = File.join(XDG.config_home, "roll/environments/#{name}")
      end
    end

    # Corresponding reference file.
    def cache
      @cache ||= File.join(File.dirname(File.dirname(file)), "references", name)
    end  

    # Read cache. If the cache does not exist, but the
    # environment does, then sync and save the cache.
    def read
      if File.exist?(cache)
        list = []
        File.readlines(cache).each do |line|
          case line
          when /^\#/, /^\s*$/
            next
          else
            list << line.strip
          end
        end
        @list = list
      elsif File.exist?(file)
        sync
        save
      end
    end

    # Save reference file.
    def save
      out = list.join("\n")
      if File.exist?(cache)
        if out != File.read(cache)
          File.open(cache, 'wb'){ |f| f << out }
        else
          puts "current: #{name}"
        end
      else
        dir = File.dirname(cache)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        File.open(cache, 'wb'){ |f| f << out }
      end
    end

    #
    #def save_environment
    #  File.open(file, 'w'){ |f| << .join("\n") }
    #end

    #def locations
    #  map{ |name, vers, path| path }
    #end

    #def names
    #  map{ |name, vers, path| name }
    #end

    #
    def each(&block)
      @list.each(&block)
    end

    #
    def size
      @list.size
    end

    #
    #def method_missing(s, *a, &b)
    #  @list.__send__(s, *a, &b)
    #end

    #
    def sync
      list = []
      sync_locations.each do |path|
        #name = load_name(path)
        #vers = load_version(path)
        #if name && vers
          list << path
        #end
      end
      @list = list
    end

    #
    def sync_locations
      locs = []
      if File.exist?(file)
        File.readlines(file).each do |line|
          line = line.strip
          next if line =~ /^\s*$/
          next if line =~ /^\#/
          dir, depth = *line.split(/\s+/)
          locs << find_projects(dir, depth)
        end
      end
      locs.flatten
    end

=begin
      #
      def locations
        @locations ||= (
          locs = []
          ledger_files.each do |file|
            File.readlines(file).each do |line|
              next if line =~ /^\s*$/
              dir, depth = *line.strip.split(/\s+/)
              locs << find_projects(dir, depth)
            end
          end
          locs.flatten
        )
      end
=end

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

=begin
    #
    def load_name(path)
      file = Dir[File.join(path, '{,.}meta', 'name')].first
      if file
        File.read(file).strip  # TODO: handle YAML
      end
    end

    # TODO: handle VERSION file
    def load_version(path)
      file = Dir[File.join(path, '{,.}meta', 'version')].first
      if file
        File.read(file).strip  # TODO: handle YAML
      end
    end
=end

    def to_s
      name
    end

  end#class Environment

end#module Roll




=begin
      # TODO: should there be a universal_ledger or shared_ledger?
      #@system_ledger_file = File.join(XDG.config_dirs.first, 'roll/ledger.list')
      #@system_ledger      = Ledger.new(@system_ledger_file)

      @user_ledger_file   = File.join(XDG.config_home, "roll/#{environment}.ledger")
      @user_ledger        = Ledger.new(@user_ledger_file)
=end
