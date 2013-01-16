# Isolate Command

Load path isolation has become the recent rage with Ruby load tools.
With Realms, isolation isn't as necessary because it already insulates
each project's files. However, for those seeking *maximum insulary protection*,
Realms provides the `isolate` command.

To use it provide the path to the project to be isolated, or if no path is
given the project in the present working directory will be used.

    `roll isolate projects/tryme/1.1`

To have a project automatically use a local isolation environment set the shell
variable $roll_isolate.

    `export roll_isolate=true`

Now when the project code is executed (with roll.rb loaded, of course), it
will have limited access to just the projects listed in it's local index.

