= Verify Command

If a project has a REQUIRE file as define by Ruby POM, then it can be used
to validate that the project's requirements are met by the load environment.

  `roll verify tmp/projects/tryme/1.1`

This will display each dependency and an indicator as to whether the
environment contains the dependency.

The standard output will look like:

  [LOAD] foo 0.8+

Which means the requirement 'foo 0.8+' was successfully loaded via the
current environment.

