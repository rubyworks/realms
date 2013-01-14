module Realms
  class Library

    # The Library::Version class is essentially a tuple (immutable array)
    # with special comparision operators.
    #
    # TODO: Get rid of this!
    #
    class Version < ::Version::Number
    end

  end
end
