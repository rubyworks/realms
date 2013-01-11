module Realms

  module Shell

    #
    # Insert paths into the roll call file.
    #
    def in
      op.banner = "Usage: roll in [PATH ...]"
      op.separator "Insert path(s) into current environment."

      parse

      paths     = argv || [Dir.pwd]

      roll_file = Roll.insert(*paths)

      puts paths.join("\n")
      puts "  '-> #{roll_file}"
    end
  end

end

