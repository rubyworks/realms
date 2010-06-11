require 'roll'

Roll::Library.load_index['roll/command'] = __FILE__

module Roll

  # = Command-line Interface
  #--
  # TODO: clean command to remove dead directories from environment
  #++
  class Command

    # Command-line arguments.
    attr :args

    # Command-line options.
    attr :opts

    # Instance of OptionParser.
    attr :op

    # Initialize and execute command.
    def self.main(*argv)
      cmd   = argv.shift
      #cmd = @argv.find{ |e| e !~ /^\-/ }
      if cmd
        require "roll/commands/#{cmd}"
        klass = ::Roll.const_get("Command#{cmd.capitalize}")
        klass.new(*argv).execute
      else
        new.fallback
      end
    end

    # New Command.
    def initialize(*argv)
      # only need optparse when command is run
      require 'optparse'
      @op   = OptionParser.new
      @argv = argv
      @opts = {}
    end

    #
    def execute
      setup

      op.on_tail("--help", "-h", "Display this help message.") do
        puts op
        exit
      end

      op.parse!

      #ARGV.shift # remove command

      call
    end

    #
    def fallback
      op.banner = "Usage: roll [COMMAND]"

      op.separator "Commands:"
      op.separator "    in  [DIR] " + (" " * 23) + "Roll directory into current environment."
      op.separator "    out [DIR] " + (" " * 23) + "Remove directory from current environment."
      op.separator "    env       " + (" " * 23) + "Show current environment."
      op.separator "    index     " + (" " * 23) + "Show current environment index."
      op.separator "    sync      " + (" " * 23) + "Synchronize environment indexes."
      op.separator "    path      " + (" " * 23) + "Output bin PATH list."
      op.separator "    verify    " + (" " * 23) + "Verify project dependencies in current environment."
      op.separator "Use 'roll COMMAND --help'"

      puts op
    end

  end

end
