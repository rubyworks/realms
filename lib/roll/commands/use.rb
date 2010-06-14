module Roll

  # Show/Change current environment.
  class CommandUse < Command

    #
    def setup
      op.banner = "Usage: roll use <NAME>"
      op.separator "Set current environment. Set name to 'system' to use RUBYENV."
      #op.on("--clear", "-c") do
      #  args.unshift 'system'
      #end
    end

    #
    def call
      name = args.first
      file = Roll.use(name)
      puts "Roll environment is now '#{File.read(file).strip}'."
    end

  end

end

