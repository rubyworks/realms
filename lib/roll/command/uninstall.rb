module Roll

  class Command

    def uninstall
      opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],

        [ '--tag',      '-t', GetoptLong::REQUIRED_ARGUMENT ],
        [ '--branch',   '-b', GetoptLong::REQUIRED_ARGUMENT ],
        [ '--revision', '-r', GetoptLong::REQUIRED_ARGUMENT ],
        [ '--version',  '-v', GetoptLong::REQUIRED_ARGUMENT ]
      )

      options = {}

      opts.each do |opt, arg|
        case opt
        when '--help'
          # TODO
        when '--tag'
          options[:version_type] = :tag
          options[:version] = arg
        when '--branch'
          options[:version_type] = :branch
          options[:version] = arg
        when '--revision'
          options[:version_type] = :revision
          options[:version] = arg
        when '--version'
          options[:version_type] = :version
          options[:version] = arg
        end
      end

      require 'roll/install'

      installer = Roll::Install::new(ARGV[1], options)

      installer.uninstall

      clean unless $PRETEND
    end

  end

end

