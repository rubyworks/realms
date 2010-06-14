module Roll

  # Show environment.
  class CommandEnv < Command

    #
    def setup
      op.banner = "Usage: roll env [NAME]"
      op.separator "Show current environment."
    end

    #
    def call
      env = Roll.env(*args)
      puts env.name + ':'
      env.lookup.each do |(path, depth)|
        puts "- #{path} #{depth}"
      end
    end

  end

end

