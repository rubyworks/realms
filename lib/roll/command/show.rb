module Roll

  class Command

    #
    def show_optparse(opts, options)
      opts.banner = "Usage: roll show [options]"
      opts.separator "Show information about installed package."
      opts.on('-g', '--github', '') do
        options[:host] = :github
      end
      opts.on('-r', '--rubyforge', '') do
        options[:host] = :rubyforge
      end
      #[ '--uri', '-u', GetoptLong::REQUIRED_ARGUMENT ]
      return opts
    end

    # Show project versions (branches/tags).
    def show(args, options)
      require 'roll/package'
      name = args.first
      installer = Package.new(name, options)
      installer.show
    end

  end

end

