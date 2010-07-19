module Roll

  # Copy an environment.
  class CommandMerge < Command

    #
    def setup
      op.banner = "Usage: roll merge [from]\n" +
                  "       roll merge [from] [to]" 
      op.separator "Merge environments."
      op.on('--sync', '-s', "Resync after merging.") do
        opts[:sync] = true
      end
    end

    # TODO:
    def call
      if args.size == 1
        name_from = args.first
        name_to   = Library.environment.name

        safegaurd(name_from, name_to)

        env_from  = Library.environment(name_from)
        env_to    = Library.environment

        env_to.merge!(env_from)
      else
        name_from = args[0]
        name_to   = args[1]

        safegaurd(name_from, name_to)

        env_from  = Library.environment(name_from)
        env_to    = Library.environment(name_to)

        env_to.merge!(env_from)
      end
      env_to.sync if opts[:sync] # TODO: maybe better just to always do it
      env_to.save
      puts "Environment `#{env_to.name}` saved."
    end

    #
    def safegaurd(name_from, name_to)
      if !Library.environments.include?(name_from)
        $stderr.puts "Environment `#{name_from}` does not exist."
        exit -1
      end
      if !Library.environments.include?(name_to)
        $stderr.puts "Environment `#{name_to}` does not exist."
        exit -1
      end
    end

  end

end

