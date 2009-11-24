require 'roll'
#require 'roll/platform'
require 'optparse'

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

      __send__("#{cmd}_optparse", parser, options) if cmd

      parser.on_tail("--help", "-h", "Display this help message.") do
        puts op
        exit
      end

      parser.parse!

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
      path = args.first
      path, file = *Roll.out(path)
      puts "#{path}"
      puts "  x <- #{file}"
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
