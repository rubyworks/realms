module Roll

  class Command #:nodoc:

    # List ledger contents.
    def list
      Library.ledger_files.each do |file|
        list = File.read(file).split("\n")
        puts list.join("\n")
      end
    end

  end

end
