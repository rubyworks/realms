module Realms

  module Shell

    #
    # Show shell stack.
    #
    def shells
      op.banner = "Usage: roll shells"
      op.separator "Display roll shell stack."

      parse

      list = ENV['roll_shell_stack'] || ''

      puts list.split(':').join("\n")
    end

  end

end

