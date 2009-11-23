module Roll

  class Command

    #
    def insert_optparse(opts, options)
      opts.banner = "Usage: roll insert"
      opts.separator "Insert present working directory into current ledger."
      return opts
    end

    # This adds a location to the user ledger.
    def insert(args, options)
      root = find_root
      if root
        env = Library.environment
        env.list << root
        env.save
        puts "#{root}"
        puts "  '-> #{Library.environment.file}"
      end
    end

  end

end

