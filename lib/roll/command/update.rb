module Roll #:nodoc:

  class Command #:nodoc:

    def update
      require 'roll/package/installer'

      opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],

        #[ '--tag',      '-t', GetoptLong::REQUIRED_ARGUMENT ],
        #[ '--branch',   '-b', GetoptLong::REQUIRED_ARGUMENT ],
        #[ '--revision', '-r', GetoptLong::REQUIRED_ARGUMENT ],

        [ '--version',  '-v', GetoptLong::REQUIRED_ARGUMENT ]
      )

      options = {}

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
          options[:version] = arg
        end
      end

      installer = Package::Installer.new(name, host_type, options)

      installer.update
    end

  end

end
