= Gem Command

The `roll gem` command it very simply. All it does is wrap the real `gem`
command in a wrapper. The `gem` command is executed as usual, but after
word Rolls looks to see if there are any environments that have been
are in of need re-syncing because of the potential changes made by the 
gems command to an environment lookup location.

In other words you can run `gem install` and have the Roll environments
that include the current gem home re-synced automatically, e.g. ...

  `roll gem install ansi`
