module Roll

  #
  class CommandShells < Command

    #
    def setup
      op.banner = "Usage: roll shells"
      op.separator "Display roll shell stack."
    end

    #
    def call
      stack = ENV['roll_shell_stack'] || ''
      puts stack.split(':').join("\n")
    end

  end

end

