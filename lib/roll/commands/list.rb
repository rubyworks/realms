module Roll

  # List available environments.
  class CommandList < Command

    #
    def setup
      op.banner = "Usage: roll list"
      op.separator "List available libraries in environment."
      op.on('--verbose', '-v', "Show detailed listing.") do
        opts[:verbose] = true
      end
    end

    #
    def call
      if opts[:verbose]
        list_verbose
      else
        list_names
      end
    end

    #
    def list_names
      names = $LEDGER.keys.sort
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
    def list_verbose 
      name = args.first
      if name and !Library.environments.include?(name)
        $stderr.puts "Environment not found."
        return
      end
      env = Library::Environment[name]
      puts env.to_s_index
    end

  end

end
