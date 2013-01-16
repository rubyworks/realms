# Where Command

The `relam where` command gives the absolute path of the file that would
be required given feature as it would be passed to the require method.
For example, to see the fullname of the file that `require "tryme"` would
actually load, we can type

    `realm where tryme`

The standard output would look something like:

    .../tmp/projects/tryme/1.1/lib/tryme.rb

Where '...' is the absolute path to this project, wherever it may reside,
since that is what we are testing.

    @stdout.assert.include?('tmp/projects/tryme/1.1/lib/tryme.rb')

Just to be sure.

