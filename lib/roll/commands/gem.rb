module Roll

  # Create an isolation index.
  class CommandGem < Command

    #
    def setup
      op.banner = "Usage: roll gem ..."
      op.separator "Run gem command and resync environment afterward."
    end

    #
    def call
      system("gem " +  args.join(' '))

      puts

      gem_envs = Library.resync_gem_environments
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

