module Roll

  class Command #:nodoc:

    DEFAULT_HOST = :rubyforge

    # Install project.
    #
    def install
      require 'roll/installer'

      opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],

        [ '--github',    '-g', GetoptLong::NO_ARGUMENT ],
        [ '--rubyforge', '-r', GetoptLong::NO_ARGUMENT ],

        [ '--version',  '-v', GetoptLong::REQUIRED_ARGUMENT ]

        #[ '--tag',      '-t', GetoptLong::REQUIRED_ARGUMENT ],
        #[ '--branch',   '-b', GetoptLong::REQUIRED_ARGUMENT ],
        #[ '--revision', '-r', GetoptLong::REQUIRED_ARGUMENT ],

        #[ '--uri', '-u', GetoptLong::REQUIRED_ARGUMENT ]
      )

      host_type = DEFAULT_HOST
      options   = {}

      opts.each do |opt, arg|
        case opt
        when '--help'
          # TODO
        when '--rubyforge'
          host_type = :rubyforge
        when '--github'
          host_type = :github
        #when '--tag'
        #  options[:version_type] = :tag
        #  options[:version] = arg
        #when '--branch'
        #  options[:version_type] = :branch
        #  options[:version] = arg
        #when '--revision'
        #  options[:version_type] = :revision
        #  options[:version] = arg
        when '--version'
          #options[:version_type] = :version
          options[:version] = arg
        end
      end

      name = ARGV[1]

      installer = Installer.new(name, host_type, options)

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

