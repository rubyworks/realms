module Roll

  # List available environments.
  class CommandList < Command

    #
    def setup
      op.banner = "Usage: roll list"
      op.separator "List available libraries in environment."
    end

    #
    def call
      names = Roll::Library.names.sort
      if names.empty?
        puts "No libraries found."
      else
        max  = names.map{ |name| name.size }.max + 4
        rows = (names.size / 4).to_i
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

  end

end
