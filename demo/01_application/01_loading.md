# Load and Require

The `library` method can be used to activate a library, constraining it to a
particular version.

    library('tryme', '1.1')

If we try to constrain a library to an incompatible version subsequent to this
a `VersionConflict` exception will be raised.

    expect Realms::Library::VersionConflict do
      library('tryme', '1.0')
    end

