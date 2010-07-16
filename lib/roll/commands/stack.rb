module Roll

  # Show environment.
  class CommandStack < Command

    #
    def setup
      op.banner = "Usage: roll stack"
      op.separator "Display environment stack."
    end

    #
    def call
      puts ENV['roll_environment_stack'] || ''
    end

  end

end

