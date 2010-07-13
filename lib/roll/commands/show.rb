module Roll

  # Show environment.
  class CommandShow < Command

    #
    def setup
      op.banner = "Usage: roll show [NAME]"
      op.separator "Show environment."
      op.on('--index', '-i', "include index listing") do
        opts[:index] = true
      end
      op.on('--yaml', '-y', "dump environment in YAML format") do
        opts[:yaml] = true
      end
    end

    #
    def call
      env = Roll::Library.env(*args)
      if opts[:yaml]
        puts env.to_yaml
      else
        puts "#{env.name}:"
        puts
        env.lookup.each do |(path, depth)|
          puts "#{path} #{depth}"
        end
        if opts[:index]
          puts
          puts env.to_s_index
        end
        puts "\n(file://#{env.file})"
      end
    end

  end

end

