# Gem Command

The `realm gem` command it very simply. All it does is wrap the real `gem`
command in a wrapper. The `gem` command is executed as usual, but afterwards
Realms looks to see if there are any environments that are in of need re-syncing
because of the potential changes made by the gems command to an environment
lookup location, i.e. `$GEM_PATH` or `$GEM_HOME`.

In other words you can run `gem install` and have the Realm cache that includes
the gem re-synced automatically:

    `realm gem install ansi`

