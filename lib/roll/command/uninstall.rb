module Roll #:nodoc:

  class Command #:nodoc:

    #
    def uninstall_optparse(opts, options)
      opts.banner = "Usage: roll uninstall [OPTIONS] [PROJECT/]<PACKAGE>"
      opts.separator "Uninstall package from local system."
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
    def uninstall(args, options)
      require 'roll/package'
      #host_type = nil

      name = args.first #ARGV[1]

      installer = Package.new(name, options)

      installer.uninstall

      clean unless $PRETEND
    end

  end #class Command

end #module Roll

