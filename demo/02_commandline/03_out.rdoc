= Out Command

To remove a lookup path from an environment, use the `out` command.

  `roll out tmp/projects`

Since `tmp/projects` was the only lookup location in the default `production`
environment, now that it has been removed we can see that there are no
entries in it's configuration file.

  text = File.read('tmp/config/roll/environments/production').strip
  text.assert == ""

When using the `out` command, if no directory is given then the current
working directory is assumed.

