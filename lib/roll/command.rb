require 'tmpdir'
require 'fileutils'
require 'getoptlong'
require 'roll'

module Roll

  # = Roll Command
  #
  class Command

    def start
      $PRETEND = ARGV.delete('--pretend')
      $VERBOSE = ARGV.delete('--verbose')
      case ARGV[0]
      when 'help', '--help', '-h'
        puts help
      when 'path', '--path', '-p'
        path
      when 'in', 'insert'
        insert
      when 'out', 'remove'
        remove
      when 'clean'
        clean
      when 'list'
        list
      when 'install'
        install
      when 'uninstall'
        uninstall
      when 'update'
        update
      when 'versions', 'show'
        show
      else
        puts "Ruby Roll"
        puts "Copyright (c) 2006 Tiger Ops"
      end
    end

  private

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
        break File.exist?('VERSION')
        break File.exist?('.config/roll.ini')
        dir = File.dirname(dir)
      end
      return nil if dir == '/'
      return dir
    end

    #
    def save_cache(list)
      FileUtils.mkdir_p(File.dirname(user_ledger_file))
      File.open(user_ledger_file, 'w') do |f|
        f << list.join("\n")
      end
    end

    #
    def user_ledger_file
      @user_ledger_file ||= File.join(XDG.home_config, 'roll/ledger.list')
    end

    #
    def help
      s = []
      s << 'usage: roll <command> [options] [arguments]'
      s << ''
      s << 'commands:'
      s << '  in         insert project into ledger'
      s << '  out        remove project from ledger'
      s << '  ledger     list ledger entries'
      s << '  clean      clean ledger of invalid entries'
      s << '  path       ledger bin PATH'
      s << '  install    install project'
      s << '  uninstall  uninstall project'
      s << '  update     update project'
      s << '  versions   list project versions'
      s.join("\n")
    end

  end

end

# Load subcommands.
require 'roll/command/path'
require 'roll/command/list'
require 'roll/command/insert'
require 'roll/command/remove'
require 'roll/command/install'
require 'roll/command/uninstall'
require 'roll/command/update'
require 'roll/command/show'

