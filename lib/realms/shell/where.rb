module Realms
  class Library
    module Shell
      register :where

      #
      # Display the absolute path of a feature.
      #
      def where
        op.banner = "Usage: realm where <feature>"
        op.separator "Display absolute path to a feature."

        #op.on('--all', '-a', "Search all rolls.") do
        #  opts[:all] = true
        #end

        parse

        feature = argv.first

        if path = $LOAD_MANAGER.find(feature)
          $stdout.puts path
        else
          $stderr.puts "Not found."
        end
      end

    end
  end
end
