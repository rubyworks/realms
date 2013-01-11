module Realms

  module Shell

    #
    # Remove path from current roll.
    #
    def out
      op.banner = "Usage: roll out [PATH ...]"
      op.separator "Remove path(s) from current roll."

      parse

      paths = argv || [Dir.pwd]

      roll_file = Roll.remove(*paths)

      puts paths.join("\n")
      puts "  '-> #{roll_file} -> [x]"
    end

  end

end
