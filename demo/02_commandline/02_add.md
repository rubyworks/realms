# Add Command

The `add` command is used to add locations to the load cache. For example,
given a set of Ruby projects under a `projects` directory, we could add all
those project with the following command.

    `realm add projects/*`

If a load cache does not exist when `add` is invoked, then a cache will be
created containing only the specified paths.

The cache is stored in the users home directory at `~/.cache/ruby/` (where `~/.cache`
is the default value for XDG_CACHE_HOME environment variable.) For the purposes
of this demonstration we have adjusted this location behind the scenes to
`cache/ruby/` (in the project's `tmp/qed/` directory). If we take a look we
will see there is a `.ledger` file there.

    ledger = Dir['cache/ruby/*.ledger'].first

To confirm that the cache has indeed been setup as expected we can read
in this file and ensure it contains the projects, which are TryMe v1.0
and TryMe v1.1.

    text = File.read(ledger)

    text.assert.include?('projects/tryme/1.0')
    text.assert.include?('projects/tryme/1.1')

