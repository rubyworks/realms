# Utils Module

The Utils module encapsulates the configuration data used to setup
the Realms system, as well as a number shared functions used throughout
the system.

## lookup_paths

Realms gets a list of globs used to lookup libraries via the `Utils#lookup_paths`
method. It's definition is desrived from the `RUBY_LIBRARY` environment setting.

    Realms::Library::Utils.lookup_paths  #=> ENV['RUBY_LIBRARY'].split(/[:;]/)

It will fallback to `GEM_PATH` or `GEM_HOME` if `RUBY_LIBRARY` is not set.

