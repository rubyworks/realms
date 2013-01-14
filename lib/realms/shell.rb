module Realms
  class Library

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
          require "realms/shell/#{cmd}"
        rescue LoadError
          cmd = 'help'
          require "realms/shell/#{cmd}"
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

end

#require 'realms/shell/copy'
require 'realms/shell/gem'
require 'realms/shell/help'
require 'realms/shell/add'
require 'realms/shell/isolate'
#require 'realms/shell/libs'
require 'realms/shell/list'
require 'realms/shell/lock'
#require 'realms/shell/merge'
require 'realms/shell/remove'
require 'realms/shell/path'
#require 'realms/shell/shells'
require 'realms/shell/show'
require 'realms/shell/ledger'
require 'realms/shell/unlock'
#require 'realms/shell/use'
require 'realms/shell/verify'
require 'realms/shell/where'

