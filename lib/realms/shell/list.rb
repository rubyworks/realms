module Realms
  class Library

    module Shell

      #
      # List available rolls.
      #
      def list
        op.banner = "Usage: roll show rolls"
        op.separator "Show list of available rolls."

        parse

        lines = []
        Roll.available_rolls.each do |r|
          if Roll.rollname == r
            lines << "=> #{r}"
          else
            lines << "   #{r}"
          end
        end
        puts lines.join("\n")
      end

    end

  end
end
