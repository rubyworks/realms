= Environment Class

The Environment class encapsulates the configuration data used to setup
the Ledger. It also provides methods for manipulating the configuration
files.

An Environment is instantiated with a single argument, the name of the
environment. If a name is not given the current environment will be used.
The current environment is determined by looking for a temporary PID-based
config file, failing that the RUBYENV environment variable, failing that
the `default` file in the users roll config directory, and lastly if all
else fails falling back to the static value "production".

  env = Roll::Environment.new
  env.name.assert == 'production'

An environment stores two essential tables for the functioning of Rolls.
The first if the lookup table. Which contains an associative array 
of [path, depth] pairs. We can add a entry to the lookup table via #append.

  env.append('tmp/projects', 2, false)

Looking at the lookup table we will see the entry is present.

  env.lookup.assert == [[File.expand_path('tmp/projects'), 2, false]]

The second important table is the index table. This table is generated
from the lookup table via the #sync method. Notice the index is presently
empty.

  env.index.assert == []

But if we sync the environment,

  env.sync

then the index will contain three entries, one for each library that exists in
the `tmp/projects` directory.

  env.index.size.assert == 3

An Environment object provides a number of means of access to it's data.
In particular Environment is Enumerable, so we can iterate over the internal
index table using #each.

  env.each do |data|
    name     = data[:name]
    version  = data[:version]
    location = data[:location]
  end

Using #each is no different than iterating over the environments index.

   env.index.each do |name, vers|
     # ...
   end

This differs from the other internal table the environment tracks, which is
the *lookup* table.

   env.lookup.each do |path, depth, dev|
      # ...
   end

The Ledger also provides a number of class methods, primarily for working with
the current environment instance. For example, per the above example, we
have a class method for *rolling-in* lookup paths.

  Roll::Environment.insert('tmp/projects', 2, false)

This will add the path, depth and development status to the internal lookup
table, resync the internal index to the adjusted lookup table and save
the result to disc --all in a single go. So now there should be a `production`
file in the user's roll config folder. In our case this is a temporary location
setup specifically for this demonstration.

  text = File.read('tmp/config/roll/environments/production')

Normally the file will by in one's home directory under `.config/roll/`.

Our projects are TryMe 1.0 and TryMe 1.1, saved in `tryme/` directories,
so we can verify the insert worked by looking for this term.

  text.assert.include?('tryme/')

