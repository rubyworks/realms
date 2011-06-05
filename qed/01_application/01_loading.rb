= Load and Require

The #library method can be used to constrain a library to a particular
version.

  library('tryme', '1.1')

If we try to constrain a library to an incompatible version a VersionConflit
will be raised.

  expect Roll::VersionConflict do
    library('tryme', '1.0')
  end

