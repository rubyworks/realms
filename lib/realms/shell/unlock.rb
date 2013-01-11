module Realms

  module Shell

    # TODO: Ultimately allow for caching a different groups?

    #
    def unlock
      op.banner = "Usage: roll unlock"
      op.separator "Clear current roll cache."

      parse

      name = argv.first

      file = Roll.unlock(name)

      if file
        puts "Unlocked: #{file}"
      else
        puts "Not locked."
      end
    end

  end

end
