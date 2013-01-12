= Library Instances

The Library class can be initialized given the location of the project.

  tryme10 = Roll::Library.new('tmp/projects/tryme/1.0')
  tryme11 = Roll::Library.new('tmp/projects/tryme/1.1')

With a library instance in hand we can query it for information about itself.

  tryme10.name.assert == "tryme"
  tryme11.name.assert == "tryme"

  tryme10.version.to_s.assert == "1.0"
  tryme11.version.to_s.assert == "1.1"

Secondary information, taken from the PROFILE, can be queried via the #profile
method.

  tryme10.profile['homepage'].assert == "http://tryme.foo"
  tryme11.profile['homepage'].assert == "http://tryme.foo"

Of course, the most important function of a library is to load and require
a script. With an Library instance in hand this can be achieved directly.

  tryme10.load('tryme.rb')
  $tryme_message.assert == "Try Me v1.0"

But if we try to load from another version, we will get a VersionConflict
error.

  expect Roll::VersionConflict do
    tryme11.load('tryme.rb')
  end

However, we can bypass this constraint (if we know what you are doing!) with
the :force option.

  tryme11.load('tryme.rb', :force=>true)
  $tryme_message.assert == "Try Me v1.1"

Notice that when requiring files directly via a Library instance, if a file
is required from two different versions of a library, a VersionConflict
error will be rasied.

  expect Roll::VersionConflict do
    tryme11.require('tryme')
  end

But there is no error if we use the active version.

  tryme10.require('tryme')

TODO: In the future, I think we will put in a version check, and a :force
option to override.

