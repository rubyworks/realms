module Realms
  class Library
    module Shell
      register :unlock
      register :clear

      #
      # Delete load cache.
      #
      def unlock
        op.banner = "Usage: relam unlock"
        op.separator "Clear current roll cache."

        parse

        name = argv.first

        if File.exist?(Utils.lock_file)
          Utils.unlock
          puts "Unlocked."
        else
          puts "Not locked."
        end
      end

      # Alias for unlock.
      alias :clear :unlock

    end
  end
end
