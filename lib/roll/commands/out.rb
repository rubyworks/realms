module Roll

  #
  class CommandOut < Command

    #
    def setup
      op.banner = "Usage: roll out [PATH ...]"
      op.separator "Remove path(s) from current roll."
    end

    #
    def call
      paths     = args || [Dir.pwd]
      roll_file = Roll.remove(*paths)

      puts paths.join("\n")
      puts "  '-> #{roll_file} -> [x]"
    end

  end

end
