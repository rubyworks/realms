module Roll

  module Shell

    #
    # List available rolls.
    #
    def list
      op.banner = "Usage: roll show rolls"
      op.separator "Show list of available rolls."

      parse

      puts Roll.available_rolls.join("\n")
    end

  end

end
