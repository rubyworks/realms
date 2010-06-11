module Roll

  # Show/Change current environment.
  class CommandEnv < Command

    #
    def setup
      op.banner = "Usage: roll env [NAME]"
      op.separator "Show current environment."
    end

    #
    def call
      puts Roll.env(*args)
    end

  end

end
