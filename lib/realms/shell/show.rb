module Realms
  class Library
    module Shell
      register :show

      #
      # Show library details.
      #
      def show
        version = nil

        op.banner = "Usage: realm show [name]"
        op.separator "Show details about a library."

        op.on('--version', '-v [VERSION]', "Show greater than or equal version.") do |val|
          version = val
        end

        parse

        name = argv.first || raise(ArgumentError, "name of library needed")

        if $LOAD_MANAGER.key?(name)
          if version
            libs = $LOAD_MANAGER[name]
            library = Array(libs).select{ |lib| lib.version.satisfy?(">= #{version}") }.min
          else
            library = $LOAD_MANAGER.current(name)
          end
        end

        if library
          puts library.metadata.to_h.to_yaml
        else
          $stderr.puts "Library not found."
        end
      end

    end
  end
end
