class Library
  require 'roll/requirements'

  # The Metadata call encapsulates a library's package,
  # profile and requirements information.
  class Metadata

    # New metadata object.
    def initialize(location, options={})
      @location = location
      @name     = options[:name]
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

    # TODO: Add other fields later
    def to_h
      load_metadata
      { :location => location,
        :name     => name,
        :version  => version.to_s,
        :loadpath => loadpath,
        :date     => date,
        :requires => requires
      }
    end

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

    # Omit from any ledger?
    #
    # TODO: Should we support +omit+ setting, or should we add a way to 
    # exclude loctions from from the environment?
    def omit?
      @omit
    end

    # Does this location have .ruby entries?
    def dotruby?
      @dot_ruby ||= File.exist?(File.join(location, '.ruby'))
    end

=begin
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
=end

    #
    def requirements
      @requirements ||= Requirements.new(location)
    end

    #
    def requires
      @requires ||= requirements.runtime
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
        #dotruby_save
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
        data = YAML.load(File.new(File.join(location, '.ruby')))
        if Hash === data
          self.name     = data['name']
          self.version  = data['version'] #|| '0.0.0')
          self.loadpath = data['loadpath'] || ['lib']
        else
          {}
        end
      elsif gemspec?
        gemspec_parse
      end
    end

#    # Save minimal `.ruby` entries.
#    def dotruby_save
#      require 'fileutils'
#      dir = File.join(location, '.ruby')
#      FileUtils.mkdir(dir)
#      File.open(File.join(dir, 'name'), 'w'){ |f| f << name }
#      File.open(File.join(dir, 'version'), 'w'){ |f| f << version.to_s }
#      File.open(File.join(dir, 'loadpath'), 'w'){ |f| f << loadpath.join("\n") }
#    end

    #
    def gemspec_parse
      #require('rubygems/specifcation'){{:legacy=>true}}
      require 'rubygems'
      spec = eval(File.read(gemspec_file))
      self.name     = spec.name
      self.version  = spec.version.to_s
      self.date     = spec.date
      self.loadpath = spec.require_paths
    end

=begin
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
=end

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

    # Fake
    #module Gem
    #  class Specification < Hash
    #    def initialize
    #      yield(self)
    #    end
    #    def method_missing(s,v=nil,*a,&b)
    #      case s.to_s
    #      when /=$/
    #        self[s.to_s.chomp('=').to_sym] = v
    #      else
    #        self[s]
    #      end
    #    end
    #  end
    #end

  end

end

