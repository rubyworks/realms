module Roll

  # Shell commands.
  #
  # TODO: This should probably be a class.
  #
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
        require "rolls/shell/#{cmd}"
      rescue LoadError
        cmd = 'help'
        require "rolls/shell/#{cmd}"
      end

      @argv = argv

      __send__(cmd)
    end

  private

    #
    # Available commands are simply the plublic instance methods.
    #
    def self.commands
      public_instance_metods(false)
    end

    #
    # Instance of OptionParser.
    #
    def op
      @op ||= OptionParser.new
    end

    #
    # Command line arguments.
    #
    def argv
      @argv
    end

    #
    # Execute the command.
    #
    def parse(argv=nil)
      @argv = argv if argv

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
      op.parse!(@argv)
    end

  end

end

require 'rolls/shell/copy'
require 'rolls/shell/gem'
require 'rolls/shell/help'
require 'rolls/shell/in'
require 'rolls/shell/isolate'
require 'rolls/shell/libs'
require 'rolls/shell/list'
require 'rolls/shell/lock'
require 'rolls/shell/merge'
require 'rolls/shell/out'
require 'rolls/shell/path'
require 'rolls/shell/shells'
require 'rolls/shell/show'
require 'rolls/shell/ledger'
require 'rolls/shell/unlock'
require 'rolls/shell/use'
require 'rolls/shell/verify'
require 'rolls/shell/where'

