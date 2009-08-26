class Library

  # Library Metadata. Delegates to Box::Package if available.

  class Metadata

    attr_reader :name

    attr_reader :version

    attr_accessor :loadpaths

    alias_method :loadpath, :loadpaths
    alias_method :loadpath=, :loadpaths=

    def initialize(library, data)
      @library = library

      data = data.inject({}) do |h, (k,v)|
        h[k.to_s.downcase.to_sym] = v; h
      end
    end

    def self.open(file, extra={})
      data = YAML.load(File.open(file))
      data = data.inject({}) do |h, (k,v)|
        h[k.to_s.downcase.to_sym] = v; h
      end
      extra = extra.inject({}) do |h, (k,v)|
        h[k.to_s.downcase.to_sym] = v; h
      end
      data.update(extra)
      new(data)
    end

    #

    def initialize(data)
      data = data.inject({}) do |h, (k,v)|
        h[k.to_s.downcase.to_sym] = v; h
      end

      if defined?(::Box)
        #@metadata = ::Box::Package.open(file, :name=>name, :version=>version.to_s)
        @metadata = ::Box::Package.new(data)
      else
        @metadata = data #Struct.new(*data.keys).new(*data.values)
      end

      def method_missing(name, *args)
        super if args.size > 0
        if val = @metadata[name]
          val
        else
          nil
        end
      end
    end

    private

      def read_package_metadata
        find = File.join(library.location, '{meta/,}package.yaml')
        Dir.glob(find)

      end

  end

end
