require 'roll'
require 'optparse'

module Roll

  class Command

    def self.run
      new.execute
    end

    #
    def initialize
    end

    #
    def execute
      cmd = ARGV.find{ |e| e !~ /^\-/ }

      parser  = OptionParser.new
      options = {}

      __send__("#{cmd}_optparse", parser, options) if cmd

      parser.on_tail("--help", "-h", "Display this help message." do
        puts op
        exit
      end

      parser.parse!

      puts "(from #{Environment.current})"

      if cmd
         __send__(cmd, ARGV, options)
      else
        # no command
      end
    end

    #
    def env_optparse(op, options)
      op.banner = "Usage: roll env [NAME]"
      op.separator "Show or switch current environment."
      op
    end

    #
    def sync_optparse(op, options)
      op.banner = "Usage: roll sync [NAME]"
      op.separator "Synchronize ledger(s) to their respective environment(s)."
      op
    end

    #
    def in_optparse(op, options)
      op.banner = "Usage: roll in [PATH]"
      op.separator "Insert path into current environment."
      op.on("--depth", "-d [INTEGER]") do |integer|
        options[:depth] = integer
      op
    end

    #
    def out_optparse(op, options)
      op.banner = "Usage: roll out [PATH]"
      op.separator "Remove path from current environment."
      op
    end

    # Show/Change current environment.
    #
    def env(args, opts)
      puts Roll.env(*args)
    end

    # Synchronize ledgers.
    #
    def sync(args, opts)
      Roll.sync(*args)
    end

    #
    def in(args, opts)
      path  = args.first
      depth = opts[:depth]
      path, file = *Roll.in(path, depth)
      puts "#{path}"
      puts "  '-> #{file}"
    end

    #
    def out(args, opts)
      path  = args.first
      path, file = *Roll.out(path)
      puts "#{path}"
      puts "  x <- #{file}"
    end

  end

end

