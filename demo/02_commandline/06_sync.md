= Sync Command

When we insert a new lookup location, the index is automatically regenerated.
However when the situation on disc changes, our index can become out-of-sync
with the reality of the projects in the lookup locations.

As demonstrate in "Roll List" we know that the current environment, the default
`production`, has two different libraries, `tryme` and `foo`. To demonstrate
`sync` let's purposefully remove the `foo` project.

  `rm -r tmp/projects/foo`

Now the environment has an index entry for a project that is no longer present.
When utilizing the environment in your scripts, this will not effect anything,
any missing projects will simply be ignored. 

To refresh the environment's index, bringing it back into sync, issue the `sync`
command.

  `roll sync`

We can take a peak at the production configuration file to verify that foo
is in fact no longer present.

  text = File.read('tmp/config/roll/environments/production')
  text.refute.include?('foo')

If we wish to re-sync all environments in one go, we can do that too by 
specifying the pseudo-environment 'all'.

  `roll sync all`

When do we need to re-sync a load environment? 

* When a project is added, removed or renamed within a lookup location.
* When a project's name or loadpath has changed.

The later means that the `.ruby/name` or `.ruby/loadpath` files would
have changed.

The `sync` command offer one last feature that allows us to check if
and environment is out-of-sync or not, without actually re-syncing.
To do this provide the `--check` or `-c` option.

  `roll sync --check`

The standard output will look like:

  Index for `production` is in-sync.

This is similar to the previously mentioned `show --status` command.

