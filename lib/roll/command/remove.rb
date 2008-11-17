module Roll

  class Command

    # This removes a location from the roll cache.
    #
    # TODO: Take matching argument.
    def remove
      root = find_root
      if root
        ledger = Roll.user_ledger
        ledger.delete(root)
        ledger.save
        puts "#{root}"
        puts "  x <- #{Roll.user_ledger_file}"
      end
    end

  end

end

