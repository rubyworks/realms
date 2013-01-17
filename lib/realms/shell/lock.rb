module Realms
  class Library
    module Shell
      register :lock
      register :cache

      #
      # Synchronize the load cache to RUBY_LIBRARY setting. This caches all the
      # neccessary information about the available libraries, so start-up times
      # are faster.
      #
      def lock
        active = false

        op.banner = "Usage: realm lock"
        op.separator "Serialize ledger and save."

        op.on('--active', '-a', "include library activity") do |val|
          active = val
        end

        parse

        file = Utils.lock(:active=>active)

        $stdout.puts "Cached at: #{Utils.lock_file}"
      end

      # Alternate term for lock.
      alias :cache :lock

    end
  end
end
