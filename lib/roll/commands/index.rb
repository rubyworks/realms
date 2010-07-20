module Roll

  #
  class CommandIndex < Command

    #
    def setup
      op.banner = "Usage: roll index [NAME]"
      op.separator "Show environment index."
    end

    # Show/Change current environment.
    #
    def call
      name = args.first
      puts Environment[name].to_s_index
    end

  end

end
