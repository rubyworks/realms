module Roll

  # Create an isolation index.
  class CommandGem < Command

    # Execute the command.
    def execute
      setup
      op.on_tail("--debug", "Run in debugging mode.") do
        $DEBUG   = true
        $VERBOSE = true
      end
      op.on_tail("--help", "-h", "Display this help message.") do
        puts op
        exit
      end
      op.order!(args)
      call
    end

    #
    def setup
      op.banner = "Usage: roll gem ..."
      op.separator "Run gem command and resync environment afterward."
      op.on("--sudo", "-s", "Run gem command as super user.") do
        opts[:sudo] = true
      end
    end

    #
    def call
      cmd = "gem " +  args.join(' ')
      cmd = "sudo " + cmd if opts[:sudo]
      if success = system(cmd)
        puts
        gem_envs = Library.sync_gem_environments
        if gem_envs.empty?
           puts "No environments required a resync."
        else
          gem_envs.each do |name|
            puts "Index for `#{name}` has been synced."
          end
        end
      end
    end

  end

end

