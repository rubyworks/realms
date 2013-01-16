# Path Command

The `path` command outputs a colon (or semi-colon) separated string of bin/
paths for the indexed libraries, which is suitable for appending to a shell
environments `PATH` variable. This can be used to setup executable lookup
on Linux systems.

Given a set of projects with executables and an current environment setup
including them, we can run the `path` command and get a list of each
project bin directory, if it has one.

    `roll path`

The standard output of which will be a colon separated list of executable
directories of the projects in the current environment.

    @stdout.assert.include?('tmp/projects/tryme/1.1/bin')

But only the latest versions of each project are included.

    @stdout.refute.include?('tmp/projects/tryme/1.0/bin')

