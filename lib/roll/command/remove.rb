module Roll

  class Command

    # This removes a location from the roll cache.
    def remove
      list = File.read(Library.user_ledger_file).split("\n")
      root = find_root
      if root
        puts "#{root}"
        list.delete(root)
        save_cache(list)
        puts "  x <- #{Library.user_ledger_file}."
      end
    end

    # Clean Roll ledger cache. This removes
    # all directories that do not exit.
    def clean
      list = File.read(Library.user_ledger_file).split("\n")
      list = list.select do |dir|
        File.directory?(dir)
      end
      save_cache(list)
    end

  end

end

