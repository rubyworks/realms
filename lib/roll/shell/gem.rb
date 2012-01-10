module Roll

  module Shell

    #
    # Run a gem command then re-lock any locked rolls that contain
    # paths in the current gem home.
    #
    def gem
      op.banner = "Usage: roll gem ..."
      op.separator "Run gem command and relock roll afterwards."
      op.on("--sudo", "-s", "Run gem command as super user.") do
        opts[:sudo] = true
      end

      op.on_tail("--debug", "Run in debugging mode.") do
        $DEBUG   = true
      end

      op.on_tail("--help", "-h", "Display this help message.") do
        puts op
        exit
      end

      op.order!(args)

      cmd = "gem "  + args.join(' ')
      cmd = "sudo " + cmd if opts[:sudo]

      gem_rolls = Roll.lock_gem_rolls

      if success = system(cmd)
        puts
        if gem_rolls.empty?
           puts "No rolls required re-locking."
        else
          puts "Locked:"
          gem_rolls.each do |name|
            puts "- #{name}"
          end
        end
      end
    end

  end

end
