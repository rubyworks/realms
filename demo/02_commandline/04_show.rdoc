= Show Command

As a developer managing load environments you want to be able to easily inspect
the current environment.

We can get a reasonable overview of the current environment using `roll show`.

  `roll show`

To get more select information, show supports special options such as 
`--index` or `-i` which displays only the project names, locations and
loadpaths.

  `roll show --index`

There is also the `--lookup` or `-l` option which shows only the lookup
directories, used to generate the index.

  `roll show --lookup`

Finally there is a `--yaml` or `-y` option for dumping the entire environment
as a serialized YAML document.

  `roll show --yaml`

Roll can also test us if an environment index is out-of-sync with the
actual projects in it's lookup table [pending]:

  `roll show --status`

