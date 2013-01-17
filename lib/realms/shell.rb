module Realms
  class Library

    # The Shell module encapsulates shell commands.
    #
    # Each command is simply a method that has been registerd via
    # the `register` dsl method.
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

        #begin
        #  require "realms/shell/#{cmd}"
        #rescue LoadError
        #  cmd = 'help'
        #  require "realms/shell/#{cmd}"
        #end

        @argv = argv

        raise "unknown command" unless commands.include?(cmd)

        __send__(cmd)
      end

    private

      #
      #
      #
      def self.register(command)
        commands << command.to_s
      end

      #
      # Available commands.
      #
      def commands
        @@commands ||= []
      end

      #
      # Instance of OptionParser.
      #
      def op
        @op ||= OptionParser.new do |opt|
          op.on_tail("--warn", "-w", "Show warnings.") do
            $VERBOSE = true
          end

          opt.on_tail("--debug", "Run in debugging mode.") do
            $DEBUG = true
          end

          opt.on_tail("--help", "-h", "Show help for command.") do
            puts op
            exit
          end
        end
      end

      #
      # Command line arguments.
      #
      def argv
        @argv
      end

      #
      # Parse the command line.
      #
      def parse(argv=nil)
        @argv = argv if argv

        #op.on_tail("--warn", "-w", "Show warnings.") do
        #  $VERBOSE = true
        #end

        #op.on_tail("--debug", "Run in debugging mode.") do
        #  $DEBUG   = true
        #end

        #op.on_tail("--help", "-h", "Display this help message.") do
        #  puts op
        #  exit
        #end

        op.parse!(@argv)
      end

    end

  end

end

require 'realms/shell/add'
require 'realms/shell/dump'
require 'realms/shell/gem'
require 'realms/shell/help'
require 'realms/shell/isolate'
require 'realms/shell/list'
require 'realms/shell/lock'
require 'realms/shell/path'
require 'realms/shell/remove'
require 'realms/shell/show'
require 'realms/shell/unlock'
require 'realms/shell/verify'
require 'realms/shell/where'

# Copyright (c)2013 Rubyworks (BSD-2-Clause License)
