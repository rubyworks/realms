module Roll

  class Command

    # This adds a location to the user ledger.
    def insert
      root = find_root
      if root
        ledger = Roll.user_ledger
        ledger << root
        ledger.save
        puts "#{root}"
        puts "  '-> #{Roll.user_ledger_file}"
      end
    end

  end

end

