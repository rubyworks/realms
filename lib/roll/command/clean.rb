module Roll

  class Command

    #
    def clean_optparse(opts, options)
      opts.banner = "Usage: roll clean [options]"
      opts.separator "Clean current ledger of any non-existent library references."
      return opts
    end

    # Clean Roll ledger cache. This removes
    # all directories that do not exit.
    def clean(args, options)
      ledger = Roll.user_ledger
      ledger.reject! do |dir|
        ! File.directory?(dir)
      end
      ledger.save
    end

  end

end

