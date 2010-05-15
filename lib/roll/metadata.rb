module Roll
  require 'yaml'  # wish we did not need this

  #--
  # TODO: Use POM? If available?
  #--
  class Metadata

    #
    def self.attr_accessor(name)
      module_eval %{
        def #{name}
          @cache[:#{name}]
        end
        def #{name}=(x)
          @cache[:#{name}] = x
        end
      }
    end

    attr :location

    attr_accessor :name

    attr_accessor :major

    attr_accessor :minor

    attr_accessor :patch

    attr_accessor :state

    attr_accessor :build

    attr_accessor :paths

    attr_accessor :arch

    attr_accessor :date

    attr_accessor :omit

    #
    def initialize(location)
      @location = location
      @cache    = {}

      if file
        data = YAML.load(File.new(file))
        if String === data
          parse_string_version(data)
        else
          data.each do |k,v|
            @cache[k.to_sym] = v
          end
        end
      end

      # override defaults
      @cache[:paths]  ||= ['lib']

      if String === @cache[:paths]
        @cache[:paths] = @cache[:paths].strip.split(/(\s+|\s*[,;:]\s*)/)
      end
    end

    # VERSION file.
    def file
      @file ||= Dir[File.join(location, "{VERSION,Version.version}{,.yaml,yml}")].first
    end

    # Get library version. 
    def version
      @version ||= (
        string = [major, minor, patch, state, build].compact.join('.')
        Version.new(string)
      )
    end

    # Get library release date. 
    #--
    # TODO: convert to date object
    #++
    def released
      date
    end

    # Get library loadpath.
    def loadpath
      paths
    end

    # Is active, i.e. not omitted.
    def active  ; !omit ; end

    # Is active, i.e. not omitted.
    def active? ; !omit ; end

    # TODO: Improve! Should this be here?
    def requires
      @requires = (
        glob = File.join(location, "{REQUEST,Reqfile}")
        file = Dir[glob].first
        if file
          data = YAML.load(File.new(file))
          data['production']['requires']
        else
          []
        end
      )
    end

    private

    #
    def parse_string_version(data)
      data = data.strip

      # name
      if md = /^(\w+)/.match(data)
        @name = md[1]
      else
        name = File.basename(File.dirname(location))
        if md = /^(\w+)/.match(data)
          @name = md[1]
        else
          raise "name needed for #{location}"
        end
      end

      # version
      if md = /(\d+\.)+(\w+\.)?(\d+)/.match(data)
        ver = md[0].split('.')
        case ver.size
        when 5
          @cache[:major], @cache[:minor], @cache[:patch], @cache[:state], @cache[:build] = *ver[0,5]
        else
          @cache[:major], @cache[:minor], @cache[:patch], @cache[:build] = *ver[0,4]
        end
      end

      # date
      if md = /\d\d\d\d-\d\d-\d\d/.match(data)
        @date = md[0] # TODO: convert to date
      end
    end

=begin

    ## Special writer for paths.
    #def paths=(x)
    #  case x
    #  when String       def #{name}
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

