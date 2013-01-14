module Realms
  class Library

    module Shell

      #
      # Display main help message.
      #
      def help
        spacer = "    %-32s %s"

        op.banner = "USAGE:\n   roll <COMMAND> [--OPT1 --OPT2 ...]\n\n" +
                    "Use 'roll <COMMAND> --help' for command details."
        op.separator " "
        op.separator "COMMANDS:"
        op.separator spacer % ["list                ", "List available rolls."]
        op.separator spacer % ["show                ", "Show current roll entries."]
        op.separator spacer % ["libs                ", "List libraries in current ledger."]
        op.separator spacer % ["ledger              ", "Display current ledger."]
        op.separator spacer % ["path                ", "Output executeables PATH list."]
        op.separator spacer % ["where               ", "Locate a library feature."]

        op.separator spacer % ["use NAME            ", "Change current roll. (Setting RUBYROLL is better!)"]
        op.separator spacer % ["shells              ", "Show use shell stack."]

        op.separator spacer % ["in  [DIR]           ", "Insert directory into current roll."]
        op.separator spacer % ["out [DIR]           ", "Remove directory from current roll."]
        op.separator spacer % ["lock                ", "Lock roll(s)."]
        op.separator spacer % ["unlock              ", "Unlock roll(s)."]

        op.separator spacer % ["copy NAME1 [NAME2]  ", "Copy roll file to new roll file."]
        op.separator spacer % ["merge NAME1 [NAME2] ", "Merge one roll file into another."]

        op.separator spacer % ["verify              ", "Verify project requirements are in current roll file."]
        op.separator spacer % ["isolate             ", "Create an isolating roll file for present project."]

        op.separator spacer % ["gem                 ", "Run gem command, then re-lock any effected roll files."]

        op.separator " "
        op.separator "OPTIONS:"

        puts op
      end

    end

  end
end
