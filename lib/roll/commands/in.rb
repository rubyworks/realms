module Roll

  # Insert paths into the roll call file.
  class CommandIn < Command
    #
    def setup
      op.banner = "Usage: roll in [PATH ...]"
      op.separator "Insert path(s) into current environment."
    end

    #
    def call
      paths     = args || [Dir.pwd]
      roll_file = Roll.insert(*paths)

      puts paths.join("\n")
      puts "  '-> #{roll_file}"
    end
  end

end

