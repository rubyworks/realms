#require 'yaml'

module Roll

  # The Metadata call encapsulates a library's package,
  # profile and requirements information.
  #
  # TODO: Improve loading and parsing of metadata.
  # We want this to be as fast and as lazy as possible.
  #
  # TODO: If method is missing delegate to PROFILE fetch.
  #
  class Metadata

    #require 'roll/metadata/pom'
    require 'roll/metadata/gem'

    # New metadata object.
    def initialize(location, name=nil, options={})
      @location = location
      @name     = name
      @version  = options[:version]
      @loadpath = options[:loadpath]
      #load_metadata
    end

    # Location of library.
    attr :location

    # Release date.
    attr_accessor :date

    # Alias for release date.
    alias_method :released, :date

    # In code name, e.g. "ActiveRecord"
    attr_accessor :codename

    # Local load paths.
    def loadpath
      @loadpath || (
        load_metadata
        @loadpath ||= ['lib']
      )
    end

    #
    def loadpath=(path)
      case path
      when nil
        path = ['lib']
      when String
        path = path.strip.split(/[,;:\ \n\t]/).map{|s| s.strip}
      end
      @loadpath = path
    end

    # Name of library.
    def name
      @name || (
        if @loaded
          nil
        else
          load_metadata
          @name
        end
      )
    end

    # Set name.
    def name=(string)
      @name = string if string
    end

    # Version number. Technically, a library should not appear in a ledger
    # list if it lacks a VERSION file. However, just in case this occurs
    # (say by a hand edited environment) we fallback to a version of '0.0.0'.
    def version
      @version || (
        load_metadata
        @version ||= Version.new('0.0.0')
      )
    end

    # Set version, converts string into Version number class.
    def version=(string)
      @version = Version.new(string) if string
    end

    # TODO: Deprecate active, if you don't want it exclude from environment.
    # Is active, i.e. not omitted.
    #def active  ; true ; end
    # Is active, i.e. not omitted.
    #def active? ; true ; end

    #
    def dot_ruby?
      @dot_ruby ||= File.exist?(File.join(location, '.ruby'))
    end

    # Access to additonal metadata outside of the .ruby directory.
    #
    # TODO: Make this information more uniform.
    def extended_metadata
      @extended_method ||= (
        profile = Dir.glob(File.join(location, 'PROFILE'), File::FNM_CASEFOLD).first
        if File.exist?(profile)
          require 'yaml'
          require 'ostruct'
          OpenStruct.new(YAML.load(profile))          
        elsif gemspec?(location)
          gem
        else
          require 'ostruct'
          OpenStruct.new
        end

        #type = [POM, Gem].find{ |m| m.match?(location) }
        #if type
        #  type.new(location)
        #else
        #  Object.new #?
        #end
      )
    end

    private #------------------------------------------------------------------

    # Load metadata.
    def load_metadata
      @loaded = true

      #dot_ruby! if !dot_ruby?

      self.name     = load_dot_ruby_file('name')
      self.version  = load_dot_ruby_file('version') #, '0.0.0')
      self.loadpath = load_dot_ruby_file('loadpath', ['lib'])
    end

    #
    def load_dot_ruby_file(name, default=nil)
      file = File.join(location, '.ruby', name)
      if File.exist?(file)
        File.read(file).strip
      else
        default
      end
    end

    #
    def save_dot_ruby
      require 'fileutils'
      dir = File.join(location, '.ruby')
      FileUtils.mkdir(dir)
      File.open(File.join(dir, 'name'), 'w'){ |f| f << name }
      File.open(File.join(dir, 'version'), 'w'){ |f| f << version.to_s }
      File.open(File.join(dir, 'loadpath'), 'w'){ |f| f << loadpath.join("\n") }
    end

    #
    def gemspec?(path)
      return true if Dir[File.join(path, '*.gemspec')].first

      pkgname = File.basename(path)
      gemsdir = File.dirname(path)
      specdir = File.join(File.dirname(gemsdir), 'specifications')
      return true if Dir[File.join(specdir, "#{pkgname}.gemspec")].first

      return false
    end

    #
    def gemspec_parse
      if !gemspec_local_file
        gemspec_parse_location
      else
        @name     = gem.name
        @version  = gem.version.to_s
        @loadpath = gem.require_paths
        #@date     = gem.date
      end
    end

    #
    def gemspec_parse_location
      pkgname = File.basename(location)

      if md = /^(.*?)\-(\d+)$/.match(pkgname)
        @name     = md[1]
        @version  = md[2]
      end

      file = File.join(location, '.require_paths')
      if File.exist?(file)
        text = File.read(file)
        @loadpath = text.strip.split(/\s*\n/)
        #@loadpath = text.split(/[,;:\ \n\t]/).map{|s| s.strip}
      end
    end

    #
    def gem
      @_gem ||= (
        require 'rubygems'
        ::Gem::Specification.load(gemspec_file)
      )
    end

    #
    def gemspec_file
      gemspec_local_file || gemspec_system_file
    end

    #
    def gemspec_local_file
      @_local__gemspec_file ||= Dir[File.join(location, '*.gemspec')].first
    end

    def gemspec_system_file
      @_gemspec_system_file ||= (
        pkgname = File.basename(location)
        gemsdir = File.dirname(location)
        specdir = File.join(File.dirname(gemsdir), 'specifications')
        Dir[File.join(specdir, "#{pkgname}.gemspec")].first
      )
    end

  end

end





=begin
    # Version file path.
    def version_file
      @version_file ||= (
        paths = Dir.glob(File.join(location, "version{.txt,.yml,.yaml,}"), File::FNM_CASEFOLD)
        paths.select{ |f| File.file?(f) }.first
      )
    end
=end

=begin
    # Load VERSION file, if it exists.
    def load_version
      if version_file
        ext = File.extname(version_file)
        if ext == '.yml' or ext == '.yaml'
          data = YAML.load(File.new(version_file))
          parse_version_hash(data)
        else
          text = File.read(version_file).strip
          if text[0..3] == '---' or text.index('major:')
            data = YAML.load(text)
            parse_version_hash(data)
          else
            parse_version_string(text)
          end
        end
        true if @version
      else
        false
      end
    end

    # Parse hash-based VERSION file.
    def parse_version_hash(data)
      data = data.inject({}){ |h,(k,v)| h[k.to_sym] = v; h }
      self.name = data[:name] if data[:name]
      self.date = data[:date] if data[:date]
      # jeweler
      if data[:major]
        self.version = data.values_at(:major, :minor, :patch, :build).compact.join('.')
      else
        vers = data[:vers] || data[:version]
        self.version = (Array === vers ? vers.join('.') : vers)
      end
      self.codename = data.values_at(:code, :codename).compact.first
    end

    # Parse string-based VERSION file.
    def parse_version_string(text)
      text = text.strip
      # name
      if md = /^(\w+)(\-\d|\ )/.match(text)
        self.name = md[1]
      end
      # version
      if md = /(\d+\.)+(\w+\.)?(\d+)/.match(text)
        self.version = md[0]
      end
      # date
      # TODO: convert to date/time
      if md = /\d\d\d\d-\d\d-\d\d/.match(text)
        self.date = md[0]
      end
    end
=end

=begin
    ## Get library active state.
    #def active
    #  return @cache[:active] if @cache.key?(:active)
    #  @cache[:active] = (
    #    case read(:active).to_s.downcase
    #    when 'false', 'no'
    #      false
    #    else
    #      true
    #    end
    #  )
    #end

    #
    def method_missing(name, *args)
      if @cache.key?(name)
        @cache[name]
      else
        @cache[name] = read(name)
      end
    end
=end

=begin
    # Retrieve entry from meta directory.
    def meta(name)
      file = Dir[File.join(location, "{meta,.meta}", name.to_s)].first
      if file
        text = File.read(file)
        if text =~ /^---/
          require_yaml
          YAML.load(text)
        else
          text.strip
        end
      else
        nil
      end
    end
=end

