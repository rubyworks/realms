module Roll

  class Command

    # This adds a location to the user ledger.
    def insert
      root = find_root
      if root
        ledger = Library.user_ledger
        ledger << root
        ledger.save
        puts "#{root}"
        puts "  '-> #{Library.user_ledger_file}"
      end
    end

  end

end

