module Roll #:nodoc:

  class Command #:nodoc:

    #
    def update_optparse(opts, options)
      opts.banner = "Usage: roll update [options]"
      opts.separator "Update previously installed package."
      opts.on('-g', '--github', '') do
        options[:host] = :github
      end
      opts.on('-r', '--rubyforge', '') do
        options[:host] = :rubyforge
      end
      opts.on('-v', '--version [VALUE]', '') do |value|
        options[:version] = value
      end
      return opts
    end

    #
    def update(args, options)
      require 'roll/package'

      #opts = GetoptLong.new(
      #  [ '--help',     '-h', GetoptLong::NO_ARGUMENT ],
      #  [ '--version',  '-v', GetoptLong::REQUIRED_ARGUMENT ]
      #  #[ '--tag',      '-t', GetoptLong::REQUIRED_ARGUMENT ],
      #  #[ '--branch',   '-b', GetoptLong::REQUIRED_ARGUMENT ],
      #  #[ '--revision', '-r', GetoptLong::REQUIRED_ARGUMENT ],
      #)

      installer = Package.new(name, options)

      installer.update
    end

  end

end
