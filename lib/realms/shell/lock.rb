module Realms
  class Library
    module Shell
      register :lock
      register :cache

      #
      # Lock load manager roll. This caches all the neccessary information
      # about the current roll, so start-up times are much faster.
      #
      def lock
        stdout = nil
        active = false

        op.banner = "Usage: realm lock"
        op.separator "Serialize ledger and save."

        op.on('--active', '-a', "include library activity") do |val|
          active = val
        end

        parse

        file = Utils.lock(:active=>active)
        $stdout.puts "Locked at: #{Utils.lock_file}"
      end

      alias :cache :lock

    end
  end
end
