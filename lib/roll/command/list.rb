module Roll

  class Command

    def list
      list = File.read(Library.user_ledger_file).split("\n")
      puts list.join("\n")
    end

  end

end
