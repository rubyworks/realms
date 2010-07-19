module Roll

  #
  class CommandSync < Command

    #
    def setup
      op.banner = "Usage: roll sync [NAME]"
      op.separator "Synchronize index to environment."
      op.on('--check', '-c', "Check environment to see if it is in-sync.") do
        opts[:check] = true
      end
    end

    #
    def call
      name = args.first || Environment.current
      if opts[:check]
        check_sync(name)
      else
        synchronize(name)
      end
    end

    #
    def check_sync(name)
      result = Roll::Library.check(name)
      if result
        puts "Index for `#{name}` is in-sync."
      else
        puts "Index for `#{name}` is out-of-sync."
      end      
    end

    # Synchronize ledgers.
    def synchronize(name)
      name = args.first
      case name
      when 'all'
        list = Environment.list
      else
        list = [name] # || Environment.current]
      end

      list.each do |name|
        result = Roll::Library.sync(name)
        if result
          puts "Index for `#{name}` has been synced."
        else
          puts "Index for `#{name}` is already current."
        end
      end
    end

  end

end

