= Which Command

The `roll which` command will tell the absolute path of file that would
be required given the path as it would be passed to the require method.
For example, to see the full name of the file that `require "tryme"` would
actually load, we can type,

  `roll which tryme`

The standard output would look something like:

  .../tmp/projects/tryme/1.1/lib/tryme.rb

Where '...' is the absolute path to this project, wherever it may reside,
since that is what we are testing.

  @stdout.assert.include?('tmp/projects/tryme/1.1/lib/tryme.rb')

Just to be sure.

