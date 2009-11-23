module Roll

  class Command #:nodoc:

    #
    def list_optparse(opts, options)
      opts.banner = "Usage: roll list [OPTIONS]"
      opts.separator "List entries in current ledger."
      return opts
    end

    # List ledger contents.
    #
    def list(args, options)
      puts "(from #{Library.current_ledger})"
      Library.ledger_files.each do |file|
        list = File.read(file).split("\n")
        puts list.join("\n")
      end
    end

  end

end
