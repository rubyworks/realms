module Roll

  #
  class CommandIndex < Command

    #
    def setup
      op.banner = "Usage: roll index [NAME]"
      op.separator "Show current environment index."
    end

    # Show/Change current environment.
    #
    def call
      puts Roll.index(*args)
    end

  end

end