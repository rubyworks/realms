module Roll

  module Shell

    # TODO: Ultimately allow for caching a different groups?

    #
    def unlock
      op.banner = "Usage: roll unlock"
      op.separator "Clear current roll cache."

      parse

      file = Roll.unlock

      puts "Unlocked `#{file}'."
    end

  end

end
