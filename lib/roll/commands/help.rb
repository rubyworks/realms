module Roll

  #
  class CommandHelp < Command

    #
    def setup
      spacer = "    %-32s %s"

      op.banner = "USAGE:\n   roll <COMMAND> [--OPT1 --OPT2 ...]\n\n" +
                  "Use 'roll <COMMAND> --help' for command details."
      op.separator " "
      op.separator "COMMANDS:"
      op.separator spacer % ["list               ", "List available environments."]
      op.separator spacer % ["use NAME           ", "Change current environment. (Setting RUBYENV is better!)"]
      op.separator spacer % ["in  [DIR]          ", "Roll directory into current environment."]
      op.separator spacer % ["out [DIR]          ", "Remove directory from current environment."]
      op.separator spacer % ["show               ", "Show current environment."]
      op.separator spacer % ["sync               ", "Synchronize environment indexes."]
      op.separator spacer % ["copy NAME1 [NAME2] ", "Copy environment to new environment."]
      op.separator spacer % ["verify             ", "Verify project dependencies are in current environment."]
      op.separator spacer % ["isolate            ", "Create an isolation index for present project."]
      op.separator spacer % ["gem                ", "Run gem command, then resync any related environments."]
      op.separator spacer % ["path               ", "Output bin PATH list."]
      op.separator " "
      op.separator "OPTIONS:"
    end

    #
    def call
      puts op
    end

  end

end
