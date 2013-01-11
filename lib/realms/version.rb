module Rolls

  class Library

    # The Library::Version class is essentially a tuple (immutable array)
    # with special comparision operators.
    #
    # TODO: Get rid of this!
    #
    class Version < ::Version::Number

      #
      # Does this version satisfy a given constraint?
      #
      # TODO: Support multiple constraints ?
      #
      def satisfy?(constraint)
        c = ::Version::Constraint.parse(constraint)
        send(c.operator, c.number)
      end

    end

  end

end
