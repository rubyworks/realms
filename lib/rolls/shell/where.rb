module Roll

  module Shell

    #
    #
    #
    def where
      op.banner = "Usage: roll where <feature>"
      op.separator "Display absolute path to a feature."
      #op.on('--all', '-a', "Search all rolls.") do
      #  opts[:all] = true
      #end

      parse

      feature = argv.first

      if path = Library.find(feature)
        $stdout.puts path
      else
        $stderr.puts "Not found."
      end
    end

  end

end