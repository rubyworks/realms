require 'roll'
#require 'roll/platform'
require 'optparse'

# TODO: clean command to remove dead directories from locals

module Roll

  # = Command-line Interface
  #
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

      options = {}

      parser  = OptionParser.new

      parser.banner = "Usage: roll [COMMAND]"

      __send__("#{cmd}_optparse", parser, options) if cmd

      if !cmd
        parser.separator "Commands:"
        parser.separator "    in     " + (" " * 29) + "Roll directory into current environment."
        parser.separator "    out    " + (" " * 29) + "Remove directory from current environment."
        parser.separator "    env    " + (" " * 29) + "Show current environment."
        parser.separator "    index  " + (" " * 29) + "Show current environment index."
        parser.separator "    sync   " + (" " * 29) + "Synchronize environment indexes."
        parser.separator "    path   " + (" " * 29) + "Output bin PATH list."
        parser.separator "    verify " + (" " * 29) + "Verify dependencies in current enironment."
        parser.separator "Options:"
      end

      parser.on_tail("--help", "-h", "Display this help message.") do
        puts parser
        exit
      end

      parser.parse!

      ARGV.shift # remove command

      if cmd
         __send__(cmd, ARGV, options)
      else
        # no command ?
      end
    end

    #
    def env_optparse(op, options)
      op.banner = "Usage: roll env [NAME]"
      op.separator "Show current environment."
      op
    end

    #
    def index_optparse(op, options)
      op.banner = "Usage: roll index [NAME]"
      op.separator "Show current environment index."
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
      op.separator "Options:"
      op.on("--depth", "-d [INTEGER]") do |int|
        options[:depth] = int
      end
    end

    #
    def out_optparse(op, options)
      op.banner = "Usage: roll out [PATH]"
      op.separator "Remove path from current environment."
      op
    end

    #
    def path_optparse(op, options)
      op.banner = "Usage: roll path"
      op.separator "Generate executable PATH list."
      op
    end

    #
    def verify_optparse(op, options)
      op.banner = "Usage: roll verify"
      op.separator "Verify dependencies in current environment."
      op
    end

    # Show/Change current environment.
    #
    def env(args, opts)
      puts Roll.env(*args)
    end

    # Show/Change current environment.
    #
    def index(args, opts)
      puts Roll.index(*args)
    end

    # Synchronize ledgers.
    #
    def sync(args, opts)
      name = args.first
      list = name ? [name] : Environment.list
      list.each do |name|
        result = Roll.sync(name)
        if result
          puts "   saved #{name}"
        else
          puts " current #{name}"
        end
      end
    end

    #
    def in(args, opts)
      path  = File.expand_path(args.first || Dir.pwd)
      depth = opts[:depth]
      path, file = *Roll.in(path, depth)
      puts "#{path}"
      puts "  '-> #{file}"
    end

    #
    def out(args, opts)
      path = File.expand_path(args.first || Dir.pwd)
      path, file = *Roll.out(path)
      puts "#{file}"
      puts "  '-> #{path} -> [x]"
    end

    #
    def verify(args, opts)
      list = Roll.verify
      list.each do |(name, constraint)|
        puts "#{name} #{constraint}"
      end
    end

    # This script builds a list of all roll-ready bin locations
    # and writes that list as an environment setting shell script.
    # On Linux a call to this to you .bashrc file. Eg.
    #
    #   if [ -f ~/.rollrc ]; then
    #       . roll
    #   fi
    #
    # Currently this only supports bash.
    #
    # TODO: It would be better to "install" executables
    # to an appropriate bin dir, using links (soft if possible).
    # There could go in ~/.bin or .config/roll/<ledger>.bin/
    #
    def path(args, opts)
      case RUBY_PLATFORM
      when /mswin/, /wince/
        div = ';'
      else
        div = ':'
      end
      env_path = ENV['PATH'].split(/[#{div}]/)
      # Go thru each roll lib and make sure bin path is in path.
      binpaths = []
      Library.list.each do |name|
        lib = Library[name]
        if lib.bindir?
          binpaths << lib.bindir
        end
      end
      #pathenv = (["$PATH"] + binpaths).join(div)
      pathenv = binpaths.join(div)
      #puts %{export PATH="#{pathenv}"}
      puts pathenv
    end

  end

end
