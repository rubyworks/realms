module Roll

  module Shell
    extend self

    #
    # Initialize and execute command. This method looks for the first
    # non-option (i.e. not starting with a `-`) entry in +argv+ array.
    # This is used as the command name, which is capitalized to match
    # the name and find the corresponding command class.
    #
    def self.main(*argv)
      require 'optparse'

      #cmd = argv.shift
      idx = argv.index{ |e| e !~ /^\-/ }
      cmd = idx ? argv.delete_at(idx) : 'help'

      begin
        require "roll/console/#{cmd}"
      rescue LoadError
        cmd = 'help'
        require "roll/console/#{cmd}"
      end

      @argv = argv

      __send__(cmd)
    end

  private

    #
    #
    #
    def self.commands
      public_instance_metods(false)
    end

    #
    #
    #
    def op
      @op ||= OptionParser.new
    end

    #
    #
    #
    def argv
      @argv
    end

    #
    # Execute the command.
    #
    def parse(argv=ARGV)
      op.on_tail("--warn", "-w", "Show warnings.") do
        $VERBOSE = true
      end
      op.on_tail("--debug", "Run in debugging mode.") do
        $DEBUG   = true
      end
      op.on_tail("--help", "-h", "Display this help message.") do
        puts op
        exit
      end
      op.parse!(argv)
    end

  end

end

require 'roll/console/copy'
require 'roll/console/gem'
require 'roll/console/help'
require 'roll/console/in'
require 'roll/console/isolate'
require 'roll/console/libs'
require 'roll/console/list'
require 'roll/console/lock'
require 'roll/console/merge'
require 'roll/console/out'
require 'roll/console/path'
require 'roll/console/shells'
require 'roll/console/show'
require 'roll/console/ledger'
require 'roll/console/unlock'
require 'roll/console/use'
require 'roll/console/verify'
require 'roll/console/where'

