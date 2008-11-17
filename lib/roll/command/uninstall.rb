module Roll

  class Command #:nodoc:

    #
    def uninstall
      require 'roll/install'

      opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],

        [ '--tag',      '-t', GetoptLong::REQUIRED_ARGUMENT ],
        [ '--branch',   '-b', GetoptLong::REQUIRED_ARGUMENT ],
        [ '--revision', '-r', GetoptLong::REQUIRED_ARGUMENT ],
        [ '--version',  '-v', GetoptLong::REQUIRED_ARGUMENT ]
      )

      host_type = nil
      options   = {}

      opts.each do |opt, arg|
        case opt
        when '--help'
          # TODO
        #when '--rubyforge'
        #  host_type = :rubyforge
        #when '--github'
        #  host_type = :github
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

      name = ARGV[1]

      installer = Installer.new(name, host_type, options)

      installer.uninstall

      clean unless $PRETEND
    end

  end #class Command

end #module Roll

