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
        require "roll/shell/#{cmd}"
      rescue LoadError
        cmd = 'help'
        require "roll/shell/#{cmd}"
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

require 'roll/shell/copy'
require 'roll/shell/gem'
require 'roll/shell/help'
require 'roll/shell/in'
require 'roll/shell/isolate'
require 'roll/shell/libs'
require 'roll/shell/list'
require 'roll/shell/lock'
require 'roll/shell/merge'
require 'roll/shell/out'
require 'roll/shell/path'
require 'roll/shell/shells'
require 'roll/shell/show'
require 'roll/shell/ledger'
require 'roll/shell/unlock'
require 'roll/shell/use'
require 'roll/shell/verify'
require 'roll/shell/where'

