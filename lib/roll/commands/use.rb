module Roll

  # Show/Change current environment.
  class CommandUse < Command

    #
    def setup
      op.banner = "Usage: roll use [name]"
      op.separator "Display/Switch current load environments."
      op.separator " "
      op.separator "NOTE: Switching environments spans a new child shell."
      op.separator "You can set RUBYENV=<name> instead to avoid this."
      #op.on("--clear", "-c") do
      #  args.unshift 'system'
      #end
    end

    #
    def call
      name = args.first
      if name
        switch_environments(name)
      else
        show_environment_list
      end
    end

    #
    def switch_environments(name)
      #file = Roll::Library.use(name)
      #puts "Roll environment is now '#{File.read(file).strip}'."

      stack = "#{ENV['roll_environment_stack']} #{Library.environment.name}".strip

      ENV['roll_environment_stack'] = stack
      ENV['roll_environment'] = name

      puts "Roll environment is now '#{name}'."

      exec("$SHELL -i")
    end

    #
    def show_environment_list
      curr = Roll::Library.env.name
      envs = Roll::Library.environments.sort
      if envs.empty?
        puts "No environments."        
      else
        puts
        envs.each do |env|
          if curr == env
            puts "=> #{env}"
          else
            puts "   #{env}"
          end
        end
        puts
      end
    end

  end

end

