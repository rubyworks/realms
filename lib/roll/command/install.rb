module Roll #:nodoc:

  class Command #:nodoc:

    DEFAULT_HOST = :rubyforge

    def install_optparse(opts, options)
      opts.banner = "Usage: roll install [OPTIONS] [<PROJECT>/]<PACKAGE>"
      opts.separator "Install package from remote source."
      opts.on('-g', '--github', 'github source') do
        options[:host] = :github
      end
      opts.on('-r', '--rubyforge', 'rubyforge source') do
        options[:host] = :rubyforge
      end
      opts.on('-v', '--verison [VALUE]', 'specify version') do |val|
        options[:version] = val
      end
      return opts
    end

    # Install project.
    #
    def install(args, options)
      require 'roll/package'

      #opts = GetoptLong.new(
      #  [ '--help',      '-h', GetoptLong::NO_ARGUMENT ],
      #  [ '--github',    '-g', GetoptLong::NO_ARGUMENT ],
      #  [ '--rubyforge', '-r', GetoptLong::NO_ARGUMENT ],
      #  [ '--version',   '-v', GetoptLong::REQUIRED_ARGUMENT ]
      #  #[ '--tag',      '-t', GetoptLong::REQUIRED_ARGUMENT ],
      #  #[ '--branch',   '-b', GetoptLong::REQUIRED_ARGUMENT ],
      #  #[ '--revision', '-r', GetoptLong::REQUIRED_ARGUMENT ],
      #  #[ '--uri', '-u', GetoptLong::REQUIRED_ARGUMENT ]
      #)

      host_type = DEFAULT_HOST

      #options   = {}

      #opts.each do |opt, arg|
      #  case opt
      #  when '--help'
      #    # TODO
      #  when '--version'
      #    #options[:type]   = :version
      #    options[:version] = arg
      #  when '--rubyforge'
      #    options[:host] = :rubyforge
      #  when '--github'
      #    options[:host] = :github
      #  #when '--tag'
      #  #  options[:version_type] = :tag
      #  #  options[:version] = arg
      #  #when '--branch'
      #  #  options[:version_type] = :branch
      #  #  options[:version] = arg
      #  #when '--revision'
      #  #  options[:version_type] = :revision
      #  #  options[:version] = arg
      #  end
      #end

      #name = args.pop #ARGV[1]

      project, package = *args.pop.split('/')

      installer = Package.new(project, package, options)

      installer.install

      #case host_type
      #when :rubyforge
      #  host = Roll::Rubyforge.new(ARGV[1], options)
      #when :github
      #  host = Roll::Github.new(ARGV[1], options)
      #else
      #  raise "unknown host"
      #end

      #dir = host.install

      # insert installation into ledger
      #if not $PRETEND
      #  Dir.chdir(dir){ insert }
      #end
    end

  end

end #module Roll

