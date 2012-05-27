= Copy Command

As developer's we want to be able to setup new library environments
based on existing environments.

To copy the current environment, we can issue the `copy` command.

  `roll copy experiment`

Where `experiment` is the name of the new load environment built from the
current environment (production). If we compare the output of their respective
indexes we will see they are exactly the same,

  `roll show --index`.assert == `roll show --index experiment`

It is also possible to copy a named environment to a new environment.

  `roll copy experiment alternate`

This will copy the `experiment` environment we just created to a new
environment called `alternate`. Again we can verify they are identical
in content.

  `roll show --index experiment`.assert == `roll show --index alternate`

If we try to copy an environment that doesn't exist, we will get an
error telling us as much.

  expect RuntimeError do
    `roll copy notaname wherever`
  end

  @stderr.assert.include?('does not exist')

If we try to copy an environment over a pre-existing environment, we will
get an error telling us that we need to use the `--force` option in order
to overwrite it.

  expect RuntimeError do
    `roll copy alternate experiment`
  end

  @stderr.assert.include?('already exists')
  @stderr.assert.include?('--force option to overwrite')

By supplying the `--force` option we can go ahead and perform the operation.

  `roll copy alternate experiment`

And again we verify the contents are identical.

  `roll show --index alternate`.assert == `roll show --index experiment`

(TODO: Note, with this last step we should alter +experiment+ first to make
the final test more robust. It's too easy to get a false positive here.
But we'll let it go for the moment.)

