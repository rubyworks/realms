# Verify Command

The `verify` command is similar to the `isolate` command, but rather the
output an isolation template, it validates that the libraries's requirements
can be met by the load environment.

    `realm verify tryme -v 1.1`

This will display each dependency and an indicator as to whether the
environment contains the dependency.

The standard output will look something like:

    ok foo 0.8+

Which means the requirement 'foo 0.8+' was successfully loaded via the
current environment.

