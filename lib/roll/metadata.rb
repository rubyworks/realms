module Roll
  require 'yaml'  # wish we did not need this

  #--
  # TODO: Use POM? If available?
  #--
  class Metadata

    #
    def initialize(location)
      @location = location

      # override defaults
      @loadpath = ['lib']

      if file
        data = YAML.load(File.new(file))
        if String === data
          parse_string_version(data)
        else
          parse_hash_version(data)
        end
      end
    end

    # VERSION file.
    def file
      @file ||= Dir[File.join(location, "{VERSION,Version.version}{,.yaml,yml}")].first
    end

    # Location of library.
    attr :location

    # Name of library.
    attr_accessor :name

    # Version number.
    attr_accessor :version

    # Release date.
    attr_accessor :date

    # Version code name, e.g. "Hardy Haron"
    attr_accessor :codename

    # Local load paths.
    attr_reader :loadpath

    #
    def loadpath=(path)
      case path
      when nil
        @loadpath = ['lib']
      when String
        @loadpath = path.strip.split(/(\s+|\s*[,;:]\s*)/)
      else
        @loadpath = path
      end
    end

    # Major version number.
    attr_reader :version

    # Set version, converts string into Version number class.
    def version=(string)
      @version = Version.new(string)
    end

    # Get library release date. 
    #--
    # TODO: convert to date object
    #++
    def released
      date
    end

    # TODO: Improve! Is this even needed?
    def requires
      @requires = (
        glob = File.join(location, "{REQUIRE,.require}{,.yml,.yaml}", File::FNM_CASEFOLD)
        file = Dir[glob].first
        if file
          data = YAML.load(File.new(file))
          data['runtime'] + data['production']
        else
          []
        end
      )
    end

    # TODO: find a different way for a lib to be manually ommited.

    # Is active, i.e. not omitted.
    def active  ; true ; end

    # Is active, i.e. not omitted.
    def active? ; true ; end

  private

    #
    def parse_hash_version(data)
      data = data.inject({}){ |h,(k,v)| h[k.to_sym] = v; h }

      self.name = data[:name]
      self.date = data[:date]

      # jeweler
      if data[:major]
        @version = data.values_at(:major, :minor, :patch, :state, :build).compact.join('.')
      else
        vers = data[:vers] || data[:version]
        self.version = (Array === vers ? vers.join('.') : vers)
      end

      self.codename = data[:code]
      self.loadpath = data[:paths]
    end

    # Parse string-based VERSION file accoring to Ruby POM standard.
    def parse_string_version(data)
      data = data.strip

      # name
      if md = /^(\w+)(\-\d|\ )/.match(data)
        self.name = md[1]
      else
        fname = File.basename(File.dirname(location))
        if /^(\w+)(\-\d|\ )/.match(fname)
          self.name = md[1]
        else
          raise "roll: name needed for #{location}"
        end
      end

      # version
      if md = /(\d+\.)+(\w+\.)?(\d+)/.match(data)
        self.version = md[0]
      end

      # date
      # TODO: convert to date/time
      if md = /\d\d\d\d-\d\d-\d\d/.match(data)
        self.date = md[0]
      end

      # loadpath
      path = []
      data.scan(/\ (\S+\/)\ /) do |path|
        path << path.chomp('/')
      end
      self.loadpath = path unless path.empty?
    end



=begin
    ## Special writer for paths.
    #def paths=(x)
    #  case x
    #  when String
    #    @paths = x.strip.split(/(\s+|\s*[,;:]\s*)/)
    #  else
    #    @paths = x
    #  end
    #end

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

  private

    #
    def read(name)
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

    #
    def require_yaml
      @require_yaml ||=(
        require 'yaml'
        true
      )
    end
=end

  end

end

