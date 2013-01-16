module Realms
  class Library
    module Shell
      register :remove
      register :rm

      #
      # Remove path from current roll.
      #
      def remove
        op.banner = "Usage: relam remove [PATH ...]"
        op.separator "Remove library path(s) from load cache."

        parse

        if argv.empty?
          paths = [Dir.pwd]
        else
          paths = argv
        end

        if Utils.locked?
          find = []

          $LOAD_MANAGER.each do |name, libs|
            Array(libs).each do |lib|
              find << [name, lib, path] if paths.any?{ |path| File.expand_path(lib.location) == File.expand_path(path) }
            end
          end

          find.each do |name, lib, path|
            puts path
            $LOAD_MANAGER[name].delete(lib)
          end

          Utils.lock(:active=>true)

          puts "  ^- #{Utils.lock_file}"
        else
          puts "Cannot remove paths unless load manager is locked."
        end
      end

      alias :rm :remove

    end
  end
end
