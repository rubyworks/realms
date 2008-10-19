module Roll

  class Command

    # This adds a location to the roll ledger cache.
    def insert
      list = File.read(Library.user_ledger_file).split("\n")
      root = find_root
      if root
        puts "#{root}"
        list = list | [root]
        save_cache(list)
        puts "  '-> #{Library.user_ledger_file}"
      end
    end

  end

end

