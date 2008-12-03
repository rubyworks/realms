module Roll

  class Command

    # Show project versions (branches/tags).
    def show
      require 'roll/package'

      opts = GetoptLong.new(
        [ '--help',      '-h', GetoptLong::NO_ARGUMENT ],
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
          options[:host] = :github
        when '--rubyforge'
          options[:host] = :rubyforge
        end
      end

      installer = Package.new(name, options)

      installer.show
    end

  end

end

