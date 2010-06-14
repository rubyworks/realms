#require File.dirname(File.dirname(__FILE__)) + '/roll.rb'
require 'roll'

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

    # New Command.
    def initialize(*argv)
      # only need optparse when command is run
      require 'optparse'
      @op   = OptionParser.new
      @args = argv
      @opts = {}
    end

    #
    def execute
      setup

      op.on_tail("--warn", "-w", "Show warnings.") do
        $VERBOSE = true
      end

      op.on_tail("--debug", "Run in debugging mode.") do
        $DEBUG   = true
        $VERBOSE = true
      end

      op.on_tail("--help", "-h", "Display this help message.") do
        puts op
        exit
      end

      op.parse!(args)

      call
    end

  end

end
