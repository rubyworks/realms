module Roll

  #
  class CommandSync < Command

    #
    def setup
      op.banner = "Usage: roll sync [NAME]"
      op.separator "Synchronize index to environment."
    end

    # Synchronize ledgers.
    #
    def call
      name = args.first
      list = name ? [name] : Environment.list
      list.each do |name|
        result = Roll.sync(name)
        if result
          puts "   saved #{name}"
        else
          puts " current #{name}"
        end
      end
    end

  end

end
