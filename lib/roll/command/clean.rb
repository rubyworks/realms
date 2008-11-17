module Roll

  class Command

    # Clean Roll ledger cache. This removes
    # all directories that do not exit.
    def clean
      ledger = Roll.user_ledger
      ledger.reject! do |dir|
        ! File.directory?(dir)
      end
      ledger.save
    end

  end

end

