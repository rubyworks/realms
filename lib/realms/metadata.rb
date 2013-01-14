module Realms
  class Library

    # The Metadata class encapsulates a library's basic information, in particular
    # name, version and load path.
    #
    class Metadata

      #
      #
      #
      def self.load(location)
        m = new(:location=>location)
        m.load_metadata
        m
      end

      #
      # Setup new metadata object.
      #
      # @param [Hash] metadata
      #   Library metadata overrides anything loaded from disc, but usually
      #   only `:location` is given.
      #
      # @option metadata [String] :location
      #   Location of project on disc. If this is provided metadata will be
      #   loaded from available `.index` or `.gemspec` file.
      #
      def initialize(metadata={})
        @table = {}

        case metadata
        when Hash
          update(metadata)
        else
          @table[:location] = metadata.to_s
          load_metadata
        end
      end

      #
      # Update metadata with data hash.
      #
      # @param [Hash] data
      #   Data to merge into metadata table.
      #
      def update(data)
        data.each do |key, value|
          __send__("#{key}=", value) if respond_to?("#{key}=")
        end
      end

      #
      # Get library location.
      #
      def location
        @table[:location]
      end

      #
      # Set library locations.
      #
      def location=(path)
        @table[:location] = path.to_s
      end

      #
      # Name of library.
      #
      def name
        @table[:name]
      end

      #
      # Set name.
      #
      def name=(string)
        @table[:name] = string.to_s if string
      end

      #
      # Version number.
      #
      # Technically, a library should not appear in a ledger list if it lacks
      # a version. However, just in case this occurs (say by a hand edited
      # environment) we fallback to a version of '0.0.0'.
      #
      def version
        @table[:version] ||= Version::Number.new('0.0.0')
      end

      #
      # Set version, converts string into Version number class.
      #
      def version=(string)
        @table[:version] = Version::Number.new(string) if string
      end

      #
      # Release date.
      #
      def date
        @table[:date]
      end

      alias_method :released, :date

      #
      # Set the date.
      #
      # TODO: Should we convert date to Time object?
      #
      def date=(date)
        @table[:date] = date
      end

      alias_method :released=, :date=

      #
      # Paths, the only one used currently is `load`.
      #
      def paths
        @table[:paths] || {}
      end

      #
      # Set paths map.
      #
      # @param [Hash] paths
      #   Paths map.
      #
      def paths=(paths)
        @table[:paths] = (
          h = {}
          paths.each do |key, val|
            val = (String === val ? split_path(val) : val)
            h[key.to_sym] = Array(val)
          end
          h
        )
      end

      #
      # Local lib paths.
      #
      def lib_paths
        paths[:lib] || ['lib']
      end

      #
      # Set the local lib paths.
      #
      def lib_paths=(paths)
        case paths
        when nil
          paths = ['lib']
        when String
          paths = split_path(path)
        end
        paths[:lib] = paths
      end

=begin
    #
    # Load path with library location.
    #
    def load_path
      lib_paths.map{ |path| File.join(location, path) }
    end

    alias_method :loadpath, :load_path
=end

      #
      # Runtime and development requirements combined.
      #
      def requirements
        @table[:requirements]
      end

      #
      # Runtime and development requirements combined.
      #
      def requirements=(requirements)
        @table[:requirements] = Array(requirements)
      end

      #
      # Runtime requirements.
      #
      def runtime_requirements
        @runtime_requirements ||= requirements.reject{ |r| r['development'] }
      end

      #
      # Development requirements.
      #
      def development_requirements
        @development_requirements ||= requirements.select{ |r| r['development'] }
      end

      # TODO: Should we support +active+ setting?

      #
      # Is the library active. If not it should be ignored.
      #
      def active?
        @active
      end

      #
      # Set active.
      #
      def active=(boolean)
        @active = boolean
      end

      #
      # Open access to non-primary metadata.
      #
      def [](name)
        @table[name.to_sym]
      end

      #
      # Does this location have `.index` file?
      #
      def dotindex?
        @_dotindex ||= File.exist?(File.join(location, '.index'))
      end

      #
      #
      #
      def gemspec?
        true if Dir[File.join(location, '*.gemspec')].first
      end

      #
      # Deterime if the location is a gem location. It does this by looking
      # for the corresponding `gems/specification/*.gemspec` file.
      #
      def gem?
        #return true if Dir[File.join(location, '*.gemspec')].first
        pkgname = File.basename(location)
        gemsdir = File.dirname(location)
        specdir = File.join(File.dirname(gemsdir), 'specifications')
        Dir[File.join(specdir, "#{pkgname}.gemspec")].first
      end

      #
      # Access to complete gemspec. This is for use with extended metadata.
      #
      def gemspec
        @gemspec ||= (
          require 'rubygems'
          ::Gem::Specification.load(gemspec_file)
        )
      end

=begin
    #
    # Verify that a library's requirements are all available in the ledger.
    # Returns a list of `[name, version]` of Libraries that were not found.
    #
    # @return [Array<String,String>] List of missing requirements.
    #
    def missing_requirements(development=false) #verbose=false)
      libs, fail = [], []
      reqs = development ? requirements : runtime_requirements
      reqs.each do |req|
        name = req['name']
        vers = req['version']
        lib = Library[name, vers]
        if lib
          libs << lib
          #$stdout.puts "  [LOAD] #{name} #{vers}" if verbose
          unless libs.include?(lib) or fail.include?([lib,vers])
            lib.verify_requirements(development) #verbose)
          end
        else
          fail << [name, vers]
          #$stdout.puts "  [FAIL] #{name} #{vers}" if verbose
        end
      end
      return fail
    end

    #
    # Like {#missing_requirements} but returns `true`/`false`.
    #
    def missing_requirements?(development=false)
      list = missing_requirements(development=false)
      list.empty? ? false : true
    end
=end

      #
      # Returns hash of primary metadata.
      #
      # @return [Hash] primary metdata
      #
      def to_h
        { 'location'     => location,
          'name'         => name,
          'version'      => version.to_s,
          'date'         => date.to_s,
          'paths'        => { 'lib' => lib_paths },
          'requirements' => requirements,
          'active'       => active
        }
      end

    private

      #
      # Load metadata.
      #
      def load_metadata
        if dotindex?
          load_dotindex
        elsif gem? or gemspec?
          load_gemspec
        end
      end

      #
      # Load metadata for .index file.
      #
      def load_dotindex
        file = File.join(location, '.index')
        data = YAML.load_file(file)
        update(data)
      end

      # Load metadata from a gemspec. This is a fallback option. It is highly 
      # recommended that a project have a `.index` file instead.
      #
      # This method requires that the `metaspec` gem be installed.  # TODO: metaspec gem name ?
      #
      # TODO: Deprecate YAML form of gemspec, RubyGems no longer supports it.
      #
      def load_gemspec
        text = File.read(gemspec_file)
        if text =~ /\A---/  
          require 'yaml'
          spec = YAML.load(text)
        else
          spec = eval(text) #, gemspec_file)
        end

        data = {}
        data[:name]    = spec.name
        data[:version] = spec.version.to_s
        data[:date]    = spec.date

        data[:paths] = {
          'load' => spec.require_paths 
        }

        data[:requirements] = []

        spec.runtime_dependencies.each do |dep|
          req = { 
            'name'    => dep.name,
            'version' => dep.requirement.to_s
          }
          data[:requirements] << req
        end

        spec.development_dependencies.each do |dep|
          req = { 
            'name'        => dep.name,
            'version'     => dep.requirement.to_s,
            'development' => true
          }
          data[:requirements] << req
        end

        update(data)
      end

      #
      # Returns the path to the .gemspec file.
      #
      def gemspec_file
        gemspec_file_system || gemspec_file_local
      end

      #
      # Returns the path to a gemspec file located in the project location,
      # if it exists. Otherwise returns +nil+.
      #
      def gemspec_file_local
        @_gemspec_file_local ||= Dir[File.join(location, '*.gemspec')].first
      end

      #
      # Returns the path to a gemspec file located in the gems/specifications
      # directory, if it exists. Otherwise returns +nil+.
      #
      def gemspec_file_system
        @_gemspec_file_system ||= (
          pkgname = File.basename(location)
          gemsdir = File.dirname(location)
          specdir = File.join(File.dirname(gemsdir), 'specifications')
          Dir[File.join(specdir, "#{pkgname}.gemspec")].first
        )
      end

      #
      #def require_indexer
      #  require 'rubygems'
      #  require 'indexer'
      #  require 'indexer/rubygems'
      #end

      #
      def split_path(path)
        path.strip.split(/[,;:\ \n\t]/).map{|s| s.strip}
      end

    end

  end

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


