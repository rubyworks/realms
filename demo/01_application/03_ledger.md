= The Ledger

At the heart of Rolls lies a ledger object. It is simply a Hash of
library names indexing library objects.

  $LEDGER.keys.assert == ['foo', 'ruby', 'tryme']

The Library class redirects a number of calls to the $LEDGER, so we
could invoke the same methods on it instead.

  Roll::Library.names.assert == $LEDGER.keys

Which we choose to use is really a matter of taste. The Roll::Library
methods were designed for readability, whereas $LEDGER is used internally.
For the rest of this demo we will use $LEDGER since this demonstration
is specifically about it.

The values of $LEDGER will always be either a Library object or an
array of Library objects, of the same name but differnt versions.

When a particular library is activated for the first time the corresponding
array value will be replaced by the library.

  $LEDGER['tryme'].assert.is_a?(Array)

  library('tryme')

  $LEDGER['tryme'].assert.is_a?(Roll::Library)

This is how Rolls handles versioning.

