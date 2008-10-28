module Roll

  class Command

    def list
      Roll.ledger_files.each do |file|
        list = File.read(file).split("\n")
        puts list.join("\n")
      end
    end

  end

end
