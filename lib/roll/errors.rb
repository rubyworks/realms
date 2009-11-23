module Roll

  # VersionError is raised when a requested version cannot be found.
  class VersionError < ::RangeError  # :nodoc:
  end

  # VersionConflict is raised when selecting another version
  # of a library when a previous version has already been selected.
  class VersionConflict < ::LoadError  # :nodoc:
  end

end

