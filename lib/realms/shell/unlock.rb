module Realms
  class Library
    module Shell
      register :unlock
      register :clear

      #
      # Remove the load cache.
      #
      def unlock
        op.banner = "Usage: relam unlock"
        op.separator "Clear current roll cache."

        parse

        file = Utils.lock_file

        if File.exist?(file)
          Utils.unlock
          puts "Removed load cache at #{file}."
        else
          puts "Not locked."
        end
      end

      # Alias for unlock.
      alias :clear :unlock

    end
  end
end
