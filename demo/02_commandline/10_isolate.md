= Isolate Command

Loadpath isolation has become the recent rage with Ruby load tools.
With Rolls, isolation isn't really necessary because it already insulates
each project's files. However, for those seeking <i>maximum insular protection</i>,
Roll provides the `isolate` command.

To use it provide the path to the project to be isolated, or if no path is
given the project in the present working directory will be used.

  `roll isolate tmp/projects/tryme/1.1`

This will create a special index called `local` in a project's .roll/environments
or .config/roll/environments directory. This special environment can be used like
any other.

To have a project automatically use a local isolation environment set the shell
variable $roll_isolate.

  `export roll_isolate=true`

Now when the project code is executed (with roll.rb loaded, of course), it
will have limited access to just the projects listed in it's local index.

Rather then set the $roll_isolate environment variable, we can also load
the 'roll/isolate' script, which will have the same effect. For example,

  `cd tmp/projects/tryme/1.1`

  `ruby -roll/isolate tryme'

We need to get back to the current directory.

  `cd ../../../../`
