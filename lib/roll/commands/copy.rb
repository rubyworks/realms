module Roll

  # Copy an environment.
  class CommandCopy < Command

    #
    def setup
      op.banner = "Usage: roll copy [to]\n" +
                  "       roll copy [from] [to]" 
      op.separator "Copy an environment."
      op.on('--sync', '-s', "Resync after copying.") do
        opts[:sync] = true
      end
      op.on('--force', '-f', "Force overwrite of pre-existing environment.") do
        opts[:force] = true
      end
    end

    #
    def call
      if args.size == 1
        name_to = args.first
        current = Library.environment

        safegaurd_copy(current.name, name_to)

        env_to  = current.copy(name_to)
      else
        name_from = args[0]
        name_to   = args[1]

        safegaurd_copy(name_from, name_to)

        env_from  = Library.environment(name_from)
        env_to    = env_from.copy(name_to)
      end
      env_to.sync if opts[:sync]
      env_to.save
      puts "Environment `#{name_to}` saved."
    end

    #
    def safegaurd_copy(name_from, name_to)
      if !Library.environments.include?(name_from)
        $stderr.puts "Environment `#{name_from}` does not exist."
        exit -1
      end
      if Library.environments.include?(name_to) && !opts[:force]
        $stderr.puts "`#{name_to}` already exists. Use --force option to overwrite."
        exit -1
      end
    end

  end

end

