# Use Command

The use command provides a convenient way to list available load environments,
see which environment is current and switching between them. To list the 
available environments simply issue the `use` command with no additional
parameters.

    `realm use`

The standard output will look like:

       development
    => production
       testing

Notice the arrow pointing to "production". This tells us which environment
is current. We can switch environments by following the `use` command with
the name of the environment desired.

    `realm use testing`

Running `realm use` again we would see:

       development
       production
    => testing

Switching between environments with `use` also means switching shells prompts. 
The `use` command actually spawns a new child shell after each invocation
in order to effect shell variables. This means we can switch back to the
previous environment quickly just by typing `exit`.

We can actually see the stack of child shells create by `use` using the `stack`
command.

    `realm stack`

The standard output of which, at this point, would look like:

    production

Which means, that if we used `exit` we would leave the "testing" environment
and return to "production".

There is another way to switch between environments, without spawning a new
child shell, by setting the RUBYENV variable manually.

    `export RUBYENV=development`

While setting the RUBYENV variable will avoid creating a new child shell,
it will not adjust PATH settings, if your shell setup is using `realm path` to
set the executable look-up locations.

Switching between environments is also instrumental in creating new
environments. For example, let's say we want to add a new experimental
load environment.

    `realm use experimental`

Invoking the `use` command to create a new load environment doesn't actually
change anything except the current environment name. So if an unwanted name
were accidentally typed, there is no harm done. Simply reissue the `use` 
command, or use `exit` to correct. 

To instantiate the new environment --writing the environments configuration
file to disc, we need to insert a *lookup* location.

    `realm in tmp/projects`

We will explore the `in` command more in the next section, for now we need
only know that it added 'tmp/projects' to the experimental environment and 
saved the environment configuration to disc. We can verify this by having
a look at the list of environments again.

    `realm use`

The standard output will look like:

       development
    => experimental
       production
       testing

