module Roll

  # Show/Change current environment.
  class CommandUse < Command

    #
    def setup
      op.banner = "Usage: roll use <NAME>"
      op.separator "Switch current load environments."
      op.separator " "
      op.separator "NOTE: This command spans a new child shell."
      op.separator "Set RUBYENV=<name> instead to avoid this."
      #op.on("--clear", "-c") do
      #  args.unshift 'system'
      #end
    end

    #
    def call
      name = args.first

      #file = Roll::Library.use(name)
      #puts "Roll environment is now '#{File.read(file).strip}'."

      stack = "#{ENV['roll_environment_stack']} #{Library.environment.name}".strip

      ENV['roll_environment_stack'] = stack
      ENV['roll_environment'] = name

      puts "Roll environment is now '#{name}'."

      exec("$SHELL -i")
    end

  end

end

