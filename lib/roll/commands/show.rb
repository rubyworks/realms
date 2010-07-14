module Roll

  # Show environment.
  class CommandShow < Command

    #
    def setup
      op.banner = "Usage: roll show [NAME]"
      op.separator "Show environment."
      op.on('--index', '-i', "Show index listing.") do
        opts[:format] = :index
      end
      op.on('--lookup', '-l', "Show lookup listing.") do
        opts[:format] = :lookup
      end
      op.on('--yaml', '-y', "Dump environment in YAML format (implies -i).") do
        opts[:format] = :yaml
      end
    end

    #
    def call
      env = Roll::Library.env(*args)
      case opts[:format]
      when :yaml
        puts env.to_yaml
      when :index
        puts env.to_s_index
      when :lookup
        puts env.to_s_lookup
      else
        puts "[#{env.name}]"
        puts
        puts env.to_s
        puts
        puts "(file://#{env.file})"
      end
    end

  end

end

