#require File.dirname(File.dirname(__FILE__)) + '/roll.rb'
#require 'roll'

module Roll

  # = Command-line interface abstract base class.
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

    # Initialize and execute command. This method looks for the first
    # non-option (i.e. not starting with a `-`) entry in +argv+ array.
    # This is used as the command name, which is capitalized to match
    # the name and find the corresponding command class.
    def self.main(*argv)
      #cmd   = argv.shift
      idx = argv.index{ |e| e !~ /^\-/ }
      cmd = idx ? argv.delete_at(idx) : 'help'
      begin
        require "roll/commands/#{cmd}"
      rescue LoadError
        cmd = 'help'
        require "roll/commands/#{cmd}"
      end
      klass = ::Roll.const_get("Command#{cmd.capitalize}")
      klass.new(*argv).execute
    end

    # New Command object.
    def initialize(*argv)
      require 'optparse' # only need optparse when command is run
      @op   = OptionParser.new
      @args = argv
      @opts = {}
    end

    # Execute the command.
    def execute
      setup

      op.on_tail("--warn", "-w", "Show warnings.") do
        $VERBOSE = true
      end
      op.on_tail("--debug", "Run in debugging mode.") do
        $DEBUG   = true
        #$VERBOSE = true
      end
      op.on_tail("--help", "-h", "Display this help message.") do
        puts op
        exit
      end

      op.parse!(args)

      call
    end

    # Override this method in subcommands to setup command options and such.
    def setup
    end

    # Override this method in run the commands procedure.
    def call
    end

  end

end
