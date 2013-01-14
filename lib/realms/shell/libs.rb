module Realms
  class Library

    module Shell

      #
      # List available libraries.
      #
      def libs
        opts = {}

        op.banner = "Usage: realm libs"
        op.separator "List available libraries."
        op.on('--verbose', '-v', "Show detailed listing.") do
          opts[:verbose] = true
        end

        parse

        if opts[:verbose]
          libs_verbose
        else
          libs_names
        end
      end

    private

      #
      def libs_names
        names = $LOAD_MANAGER.keys.sort
        if names.empty?
          puts "No libraries found."
        else
          max  = names.map{ |name| name.size }.max + 4
          rows = ((names.size + 4) / 4).to_i
          cols = []
          names.each_with_index do |name, i|
            c = i % rows
            cols[c] ||= []
            cols[c] << name
          end
          out = ""
          cols.each do |row|
            row.each do |name|
              out << ("%-#{max}s" % [name])
            end
            out << "\n"
          end
          puts out
        end
      end

      #
      def libs_verbose 
        name = argv.first
        if name and !Roll.available_rolls.include?(name)
          $stderr.puts "Roll not found."
          return
        end
        env = Roll::Environment[name]
        puts env.to_s_index
      end

    end

  end
end
