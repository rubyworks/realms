module Roll

  class Command

    # Show project versions (branches/tags).
    def show
      require 'roll/install'

      opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],

        [ '--github',    '-g', GetoptLong::NO_ARGUMENT ],
        [ '--rubyforge', '-r', GetoptLong::NO_ARGUMENT ]

        #[ '--uri', '-u', GetoptLong::REQUIRED_ARGUMENT ]
      )

      options = {}

      opts.each do |opt, arg|
        case opt
        when '--help'
          # TODO
        when '--github'
          host_type = :github
        when '--rubyforge'
          host_type = :rubyforge
        end
      end

      installer = Installer.new(name, host_type, options)

      installer.show
    end

  end

end

