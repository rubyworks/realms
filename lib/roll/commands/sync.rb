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
      case name
      when 'nil'
        list = [Environment.current]
      when 'all'
        list = Environment.list
      else
        list = [name]
      end

      list.each do |name|
        result = Roll::Library.sync(name)
        if result
          puts "Index for `#{name}` has been build."
        else
          puts "Index for `#{name}` is already current."
        end
      end
    end

  end

end

