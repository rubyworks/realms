module Realms

  module Shell

    #
    # Show/Change current environment.
    #
    def use
      op.banner = "Usage: roll use [name]"
      op.separator "Display/Switch current roll."
      op.separator " "
      op.separator "NOTE: Switching rolls spawns a new child shell."
      op.separator "You can set $ROLL_FILE=<name> instead to avoid this."
      #op.on("--clear", "-c") do
      #  args.unshift 'system'
      #end

      parse

      name = args.first

      if name
        switch_rolls(name)
      else
        show_rolls
      end
    end

  private

    #
    def switch_rolls(name)
      shell_stack = ENV['roll_shell_stack']

      old_roll_file = Roll.roll_file
      new_roll_file = Roll.construct_roll_name(name)

      stack = "#{shell_stack}:#{old_roll_file}"

      ENV['roll_shell_stack'] = stack
      ENV['roll_file'] = new_roll_file

      puts "Roll is now `#{name}'."

      exec("$SHELL") # -i")
    end

    #
    def show_rolls
      curr = ::Roll.environment.name
      envs = ::Roll.environments.sort
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
