module Roll

  # List available environments.
  class CommandList < Command

    #
    def setup
      op.banner = "Usage: roll list"
      op.separator "List current environments."
    end

    #
    def call
      curr = Roll.env.name
      envs = Roll.list.sort #(*args)
      if envs.empty?
        puts "No environments."        
      else
        puts
        envs.each do |env|
          if curr == env
            puts "=> #{env}"
          else
            puts "   #{env}"
          end
        end
        puts
      end
    end

  end

end
