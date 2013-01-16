module Realms
  class Library
    module Shell
      register :help

      #
      # Display main help message.
      #
      def help
        spacer = "    %-32s %s"

        op.banner = "USAGE:\n   realm <COMMAND> [--OPT1 --OPT2 ...]"

        op.separator " "
        op.separator "COMMANDS:"
        op.separator spacer % ["list                ", "List available libraries."]
        op.separator spacer % ["dump                ", "Dump serialized ledger."]
        op.separator spacer % ["path                ", "Output bin PATH list."]
        op.separator spacer % ["show <NAME>         ", "Show library details."]
        op.separator spacer % ["where <FEATURE>     ", "Locate a library feature."]
        op.separator spacer % ["add <DIR>           ", "Insert directory into current ledger."]
        op.separator spacer % ["rm  <DIR>           ", "Remove directory from current ledger."]
        op.separator spacer % ["lock                ", "Cache load ledger."]
        op.separator spacer % ["unlock              ", "Unlock load ledger."]
        op.separator spacer % ["verify              ", "Verify library requirements are available."]
        op.separator spacer % ["isolate             ", "Create an isolation list for a library."]
        #op.separator spacer % ["gem                 ", "Run gem command, then re-lock ledger."]

        op.separator " "
        op.separator "GENERAL OPTIONS:"

        puts op
      end

    end

  end
end
