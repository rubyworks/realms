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
      op.separator spacer % ["list                ", "List available roll files."]
      op.separator spacer % ["use NAME            ", "Change current roll file. (Setting ROLL_FILE is better!)"]
      op.separator spacer % ["in  [DIR]           ", "Insert directory into current roll file."]
      op.separator spacer % ["out [DIR]           ", "Remove directory from current roll file."]
      op.separator spacer % ["show                ", "Show current roll file."]
      op.separator spacer % ["lock                ", "Lock roll(s)."]
      op.separator spacer % ["copy NAME1 [NAME2]  ", "Copy roll file to new roll file."]
      op.separator spacer % ["merge NAME1 [NAME2] ", "Merge one roll file into another."]
      op.separator spacer % ["verify              ", "Verify project requirements are in current roll file."]
      op.separator spacer % ["isolate             ", "Create an isolating roll file for present project."]
      op.separator spacer % ["gem                 ", "Run gem command, then re-lock any effected roll files."]
      op.separator spacer % ["path                ", "Output executeables PATH list."]
      op.separator spacer % ["where               ", "Locate a library script."]
      op.separator " "
      op.separator "OPTIONS:"
    end

    #
    def call
      puts op
    end

  end

end
