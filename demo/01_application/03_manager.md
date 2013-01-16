# The Manager

At the heart of Realms lies a global Manager instanace. It is essentially a Hash
of library names indexing library objects.

    $LOAD_MANAGER.keys.sort.assert == ['foo', 'ruby', 'tryme']

The Library class redirects a number of calls to the $LOAD_MANAGER, so we could
invoke the same methods on it instead.

    Realms::Library.names.assert == $LOAD_MANAGER.keys

Which we choose to use is mostly a matter of taste. The Realms::Library class
methods were designed for end-user readability, whereas $LOAD_MANAGER is used
internally. For the rest of this demo we will use $LOAD_MANAGER since this
demonstration is specifically about it.

The values of $LOAD_MANAGER will always be either a Library object or an array
of Library objects of the same name but differnt versions.

When a particular library is activated for the first time the corresponding
array value will be replaced by that library.

    $LOAD_MANAGER['tryme'].assert.is_a?(Array)

    library('tryme')

    $LOAD_MANAGER['tryme'].assert.is_a?(Realms::Library)

This is how Realms handles version control.

