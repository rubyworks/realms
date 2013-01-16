module Realms
  class Library

    # Raise when two versions come into conflict.
    #
    class VersionConflict < ::Version::Error
    end

  end
end
