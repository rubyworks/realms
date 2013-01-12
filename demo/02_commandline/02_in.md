= Insert Command

When first using Roll, there will be no environments setup, thus the first
thing to do is create an environment. For the purpose of this demonstration
we have places some sample projects in `tmp/projects`. To add a lookup location
to our load environment we use the `in` command.

  `roll in tmp/projects`

The default environment is called `production`. So the above command will
create a `production` environment containing entries for the projects located
in `tmp/projects`. By default the `roll in` command searches for conforming
projects two directories below the given directory. This is usually sufficient,
as most project directories have projects either directly within them or one
level below that. You can adjust the search depth with the `--depth`/`-d`
option, if need be.

  `roll in -d3 tmp/projects`

Roll environment settings are stored in the users home directory under
`.config/roll/environments` (where `.config` is the default value for
XDG_CONFIG_HOME environment variable.)

For the purposes of this demonstration we have adjusted this location behind
the scenes to `tmp/config/roll/environments`. If we take a look we will see that
a file named `production` exists.

  File.assert.exist?('tmp/config/roll/environments/production')

To confirm that the environment has indeed been setup as expected we can read
in the environment configuration file and ensure it contains the projects,
which are TryMe v1.0 and TryMe v1.1.

  text = File.read('tmp/config/roll/environments/production')

  text.assert.include?('tmp/projects/tryme/1.0')
  text.assert.include?('tmp/projects/tryme/1.1')

