module Realms
  class Library

    module Shell

      # TODO: lookup root by matching .index relative to path?

      #
      # Verify that a project's requirements are in the current roll call.
      #
      def verify
        op.banner = "Usage: roll verify [path]"
        op.separator "Verify dependencies in current roll."

        parse

        location = argv.first || Dir.pwd

        library = Library.new(location)

        if library.requirements.empty?
          puts "Project #{library.name} has no requirements."
        else
          library.requirements.verify(true) # verbose
        end

        #list.each do |(name, constraint)|
        #  puts "#{name} #{constraint}"
        #end
      end

    end

  end
end
