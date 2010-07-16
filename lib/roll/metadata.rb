#require 'yaml'

module Roll

  # The Metadata call encapsulates a library's package,
  # profile and requirements information.
  #
  # TODO: Improve loading and parsing of metadata.
  # We want this to be as fast and as lazy as possible.
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
      @loaded   = false
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

    # Set the loadpath.
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
          nil # TODO: raise error here?
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

    # Is active, i.e. not omitted.
    #
    # TODO: Should we support +active+ setting, or should we add a way to 
    # exclude loctions from from the environment?
    def active?
      true
    end

    # Does this location have .ruby entries?
    def dotruby?
      @dot_ruby ||= File.exist?(File.join(location, '.ruby'))
    end

=begin
    # Access to additonal metadata outside of the .ruby/ directory.
    #
    # TODO: Make this information more uniform beteen POM PROFILE and
    # RubyGems GEM::Specification; and think of a shorter name.
    def extended_metadata
      @extended_method ||= (
        profile = Dir.glob(File.join(location, 'PROFILE'), File::FNM_CASEFOLD).first
        if profile && File.exist?(profile)
          require 'yaml'
          require 'ostruct'
          OpenStruct.new(YAML.load(profile))          
        elsif gemspec?
          gemspec
        else
          require 'ostruct'
          OpenStruct.new
        end
      )
    end
=end

    # Does the project have a PROFILE?
    def profile?
      Dir.glob(File.join(location, 'PROFILE'), File::FNM_CASEFOLD).first
    end

    # Return the PROFILE data as Hash. If the project does not have
    # a profile, then return an empty Hash.
    def profile
      @_profile ||= (
        if file = profile?
          require 'yaml'
          #- require 'ostruct'
          #- OpenStruct.new(YAML.load(profile))
          YAML.load(File.new(file))
        else
          #- OpenStruct.new
          {}
        end
      )
    end

    # Deterime if the location is a gem location. It does this by looking
    # for the corresponding `gems/specification/*.gemspec` file.
    def gemspec?
      #return true if Dir[File.join(location, '*.gemspec')].first
      pkgname = File.basename(location)
      gemsdir = File.dirname(location)
      specdir = File.join(File.dirname(gemsdir), 'specifications')
      Dir[File.join(specdir, "#{pkgname}.gemspec")].first
    end

    # Access to complete gemspec. This is for use with extended metadata.
    def gemspec
      @_gemspec ||= (
        require 'rubygems'
        ::Gem::Specification.load(gemspec_file)
      )
    end

    # Ensure there is a set of dotruby entries. Presently this just checks to
    # see if there are .ruby/ entries. If not and it is a gem location, it will
    # use the gem's information to write the .ruby entries.
    #
    # NOTE: There is no further fallback, as there does not seem to be any other
    # reliable means for determining the minimum information (though Bundler
    # is pushing the version.rb file, but I am suspect of this design).
    # There is also the possible VERSION file, but there are at least three
    # differnt formats for this file in common use --I am not sure it's worth
    # the coding effort. Just add the .ruby entires already!
    def dotruby_ensure
      return location if dotruby?
      if gemspec?
        gemspec_parse
        dotruby_save
        return location
      else
        return nil
      end
    end

    private #------------------------------------------------------------------

    # Load metadata.
    def load_metadata
      @loaded = true
      if dotruby?
        self.name     = dotruby_load_file('name')
        self.version  = dotruby_load_file('version') #, '0.0.0')
        self.loadpath = dotruby_load_file('loadpath', ['lib'])
      elsif gemspec?
        gemspec_parse
      end
    end

    # Load `.ruby/<name>` file and strip whitespace.
    def dotruby_load_file(name, default=nil)
      file = File.join(location, '.ruby', name)
      if File.exist?(file)
        File.read(file).strip
      else
        default
      end
    end

    # Save minimal `.ruby` entries.
    def dotruby_save
      require 'fileutils'
      dir = File.join(location, '.ruby')
      FileUtils.mkdir(dir)
      File.open(File.join(dir, 'name'), 'w'){ |f| f << name }
      File.open(File.join(dir, 'version'), 'w'){ |f| f << version.to_s }
      File.open(File.join(dir, 'loadpath'), 'w'){ |f| f << loadpath.join("\n") }
    end

    # Extract the minimal metadata from a gem location. This does not parse
    # the actual gemspec, but parses the gem locations basename and looks for
    # the presence of a `.require_paths` file. This is much more efficient.
    def gemspec_parse
      pkgname = File.basename(location)
      if md = /^(.*?)\-(\d+.*?)$/.match(pkgname)
        self.name     = md[1]
        self.version  = md[2]
      else
        raise "Could not parse name and version from gem at `#{location}`."
      end
      file = File.join(location, '.require_paths')
      if File.exist?(file)
        text = File.read(file)
        self.loadpath = text.strip.split(/\s*\n/)
      else
        self.loadpath = ['lib'] # TODO: also ,'bin'] ?
      end
    end

    #--
    #def gemspec_parse
    #  if !gemspec_local_file
    #    gemspec_parse_location
    #  else
    #    @name     = gem.name
    #    @version  = gem.version.to_s
    #    @loadpath = gem.require_paths
    #    #@date     = gem.date
    #  end
    #end
    #++

    # Returns the path to the .gemspec file.
    def gemspec_file
      gemspec_system_file || gemspec_local_file
    end

    # Returns the path to a gemspec file located in the project location,
    # if it exists. Otherwise returns +nil+.
    def gemspec_local_file
      @_local__gemspec_file ||= Dir[File.join(location, '*.gemspec')].first
    end

    # Returns the path to a gemspec file located in the gems/specifications
    # directory, if it exists. Otherwise returns +nil+.
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

