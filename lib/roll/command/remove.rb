module Roll

  class Command #:nodoc:

    #
    def remove_optparse(opts, options)
      opts.banner = "Usage: roll remove [options]"
      opts.separator "Remove present working directory from current ledger."
      return opts
    end

    # This removes a location from the roll cache.
    #
    # TODO: Take matching argument. instead of root?
    def remove(args, options)
      if args.first
        dir = File.expand_path(args.first)
      else
        dir = find_root
      end
      if root
        ledger = Library.user_ledger
        ledger.delete(root)
        ledger.save
        puts "#{root}"
        puts "  x <- #{Library.user_ledger_file}"
      end
    end

  end

end

