module Realms
  class Library
    module Shell
      register :verify

      #
      # Verify that a library's requirements are available.
      #
      # @return nothing
      #
      def verify
        version = nil
        development = nil

        op.banner = "Usage: realm verify [name]"
        op.separator "Verify dependencies are available."

        op.on('--version', '-v [VERSION]', "version constraint") do |val|
          version = val
        end

        op.on('--development', '-d', "include development requirements") do |val|
          development = val
        end

        parse

        name = argv.first

        if name
          library = $LOAD_MANAGER.current(name, version)
        else
          root = Dir.pwd  # TODO: lookup root of project?
          library = $LOAD_MANAGER.add(root)
        end

        if library.requirements.empty?
          puts "Project #{library.name} has no requirements."
        else
          verify_via_isolation(library, development)
        end
      end

      #
      #
      #
      def verify_via_isolation(library, development)
        $LOAD_MANAGER.isolate_library(library, development)
        $LOAD_MANAGER.each do |name, lib|
          puts "\u2713 %s %s" % ["#{lib.name}-#{lib.version}", lib.location]
        end
      end

      #
      #
      #
      #def verify_via_activation(library, development)
      #  $LOAD_MANAGER.activate_library(library)
      #  $LOAD_MANAGER.verify_library(library, development)
      #  puts "#{library.name}-#{library.version} looks good"
      #end

    end
  end
end
