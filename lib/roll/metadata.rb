module Roll

  #--
  # TODO: Use POM? If available?
  #--
  class Metadata

    #TODO: hide most methods

    attr :location

    #
    def initialize(location)
      @location = location
      @cache = {}
    end

    # Get library name.
    def name
      @cache[:name] ||= read('name')
    end

    # Get library version. 
    #--
    # TODO: handle VERSION file
    # TODO: handle YAML
    #++
    def version
      @cache[:version] ||= Version.new(read(:version))
    end

    # Get library active state.
    def active
      return @cache[:active] if @cache.key?(:active)
      @cache[:active] = (
        case read(:active).to_s.downcase
        when 'false', 'no'
          false
        else
          true
        end
      )
    end

    # Get library release date. 
    #--
    # TODO: default date to what?
    #++
    def released
      @cache[:released] ||= read(:released) || "1900-01-01"
    end

    # Get library loadpath.
    def loadpath
      @cache[:loadpath] ||= (
        val = read(:loadpath).to_s.strip.split(/\s*\n/)  # TODO: handle YAML
        val = ['lib'] if val.empty?
        val
      )
    end

    #
    def requires
      @cache[:requires] ||= (
        if entry = read(:requires)
          entry.strip.split("\n").map do |line|
            line.strip.split(/\s+/)
          end
        else
          []
        end
      )
    end

    #
    def method_missing(name, *args)
      if @cache.key?(name)
        @cache[name]
      else
        @cache[name] = read(name)
      end
    end

  private

    #--
    # TODO: handle YAML
    #++
    def read(name)
      file = Dir[File.join(location, "{meta,.meta}", name.to_s)].first
      if file
        File.read(file).strip
      else
        nil
      end
    end

  end

end
