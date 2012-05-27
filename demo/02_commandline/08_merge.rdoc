= Merge Command

Another useful command for working with load environments is `merge`.
As the name indicates, `merge` makes it possible to take one environment
and combine it with another.

  `roll merge testing development`

This example would merge the `testing` environment into the `development`
environment. To merge a load environment into the current environment
simply leave out the last argument.

  `roll merge testing`

So in this case we've merged the testing environment into the current environment,
namely the default, `production`.

If we try to merge an environment that doesn't exist, we will get an
error telling us as much.

  expect RuntimeError do
    `roll merge notaname wherever`
  end

  @stderr.assert.include?('does not exist')

