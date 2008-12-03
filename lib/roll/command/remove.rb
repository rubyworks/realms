module Roll

  class Command #:nodoc:

    # This removes a location from the roll cache.
    #
    # TODO: Take matching argument.
    def remove
      root = find_root
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

