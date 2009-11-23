require 'tmpdir'
require 'fileutils'
#require 'getoptlong'
require 'roll'

require 'optparse'

module Roll
  VERSION   = "1.0.0"
  COPYRIGHT = "Copyright (c) 2006,2009 Thomas Sawyer"
  LICENSE   = "GPLv3"

  # = Roll Command
  #
  # TODO: Need to make command pluggable. The COMMAND_INDEX must go!
  #
  class Command

    COMMAND_INDEX = {
      'help'=>:help, '--help'=>:help, '-h'=>:help,
      'version'=>:version, '--version'=>:version, '-v'=>:version,
      'path'=>:path, '--path'=>:path, '-p'=>:path,
      'insert'=>:insert, 'in'=>:insert,
      'remove'=>:remove, 'rm'=>:remove, 'out'=>:remove,
      'clean'=>:clean,
      'list'=>:list,
      'ledger'=>:ledger,
      'install'=>:install,
      'uninstall'=>:uninstall,
      'update'=>:update,
      'show'=>:show,
      'sync'=>:sync
    }

    def start
      $PRETEND = ARGV.delete('--pretend') || ARGV.delete('--dryrun')
      $VERBOSE = ARGV.delete('--verbose')

      idx = ARGV.shift
      cmd = COMMAND_INDEX[idx]

      if !cmd
        puts "Unknown command. Try 'roll help'."
        exit
      end

      case cmd
      when :help
        puts help
        exit
      when :version
        puts version
        exit
      end

      opts = OptionParser.new

      options = {}

      send("#{cmd}_optparse", opts, options)

      opts.on("--debug", "debug mode") do
        $DEBUG = true
      end

      opts.on_tail("-h", "--help", "show this message") do
        puts opts
        exit
      end
      
      opts.parse! #(args)

      args = ARGV.dup

      begin
        send("#{cmd}", args, options)
      rescue => err
        raise err if $DEBUG
        puts err
      end
    end

  private

    #def help_optparse(opts, options)
    #end

    #def help(args, opts)
    #  puts opts
    #end

    #
    def windows?
      processor, platform, *rest = RUBY_PLATFORM.split("-")
      /ms/ =~ platform   # better?
    end

    # FIXME: break on ?
    #
    def find_root
      dir = Dir.pwd
      until dir == '/'
        break File.directory?('meta')
        break File.directory?('.meta')
        dir = File.dirname(dir)
      end
      return nil if dir == '/'
      return dir
    end

    #
    def save_cache(list)
      FileUtils.mkdir_p(File.dirname(user_ledger_file))
      File.open(user_ledger_file, 'wb') do |f|
        f << list.join("\n")
      end
    end

    #
    def user_ledger_file
      @user_ledger_file ||= File.join(XDG.config_home, 'roll/ledger.list')
    end

    #
    def help
      s = []
      s << 'Usage: roll <command> [options] [arguments]'
      s << ''
      s << 'Ledger Commands:'
      s << '  insert  in         insert current project into ledger'
      s << '  remove  out        remove current project from ledger'
      s << '  list               list the ledger entries'
      s << '  clean              clean ledger of invalid entries'
      s << '  path               output ledger bin PATH'
      s << ''
      s << 'Installation Commands:'
      s << '  install            install package'
      s << '  uninstall          uninstall package'
      s << '  update             update package'
      s << '  show               show package information'
      s << ''
      s << 'General Commands:'
      s << '  help               see this help messge'
      s << '  version            see this help messge'
      s << ''
      s << "For help with a command use 'roll <COMMAND> --help."
      s.join("\n")
    end

    def version
      "Roll v#{VERSION}\n#{COPYRIGHT}\nDistributed under the terms of the #{LICENSE} license"
    end

  end

end

# Load subcommands.
require 'roll/command/clean'
require 'roll/command/path'
require 'roll/command/list'
require 'roll/command/insert'
require 'roll/command/remove'
require 'roll/command/install'
require 'roll/command/uninstall'
require 'roll/command/update'
require 'roll/command/ledger'
require 'roll/command/show'
require 'roll/command/sync'


