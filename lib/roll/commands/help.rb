module Roll

  #
  class CommandHelp < Command

    #
    def setup
      op.banner = "USAGE:\n   roll <COMMAND> [--OPT1 --OPT2 ...]\n\n" +
                  "Use 'roll <COMMAND> --help' for command details."
      op.separator " "
      op.separator "COMMANDS:"
      op.separator "    use NAME  " + (" " * 23) + "Change current environment."
      op.separator "    list      " + (" " * 23) + "List available environments."
      op.separator "    in  [DIR] " + (" " * 23) + "Roll directory into current environment."
      op.separator "    out [DIR] " + (" " * 23) + "Remove directory from current environment."
      op.separator "    show      " + (" " * 23) + "Show current environment."
      op.separator "    index     " + (" " * 23) + "Show current environment index."
      op.separator "    sync      " + (" " * 23) + "Synchronize environment indexes."
      op.separator "    path      " + (" " * 23) + "Output bin PATH list."
      op.separator "    verify    " + (" " * 23) + "Verify project dependencies in current environment."
      op.separator " "
      op.separator "OPTIONS:"
    end

    #
    def call
      puts op
    end

  end

end
