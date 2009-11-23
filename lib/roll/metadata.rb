module Roll

  #--
  # TODO: Use POM if available?
  #--
  class Metadata

    #TODO: hide most methods

    #
    def initialize(location)
      @location = location
      @cache = {}
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

    # TODO: handle YAML
    def read(name)
      file = Dir[File.join(location, "{meta,.meta}", name)].first
      if file
        File.read(file).strip
      else
        nil
      end
    end

  end

end
