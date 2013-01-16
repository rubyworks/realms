module Realms
  class Library
    module Shell

      register :add

      #
      # Add paths into the current libraries.
      #
      def add
        op.banner = "Usage: realm add [PATH ...]"
        op.separator "Add library path(s) into locked load environment."

        parse

        if argv.empty?
          paths =  [Dir.pwd]
        else
          paths = argv
        end

        if Utils.locked?
          paths.each do |path|
            puts path
            $LOAD_MANAGER.add(path)
          end
          Utils.lock(:active=>true)
          puts "  '-> #{Utils.lock_file}"
        else
          puts "Cannot add paths unless load manager is locked."
          puts "Export to RUBY_LIBRARY environment variable to add paths for live usage."
        end
      end

    end
  end
end
