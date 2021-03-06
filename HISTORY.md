# RELEASE HISTORY

## 2.0.0 / 2012-01-08

Ruby Rolls and spun-off the underlying Library and Library::Ledger
classes as a separate project. This serves two important purposes.
First, Library reserves it's namespace in gem space. And second,
the separation helps focus the purpose of each project. Where Library
provides the object basis of working with libraries. Whereas Rolls
provides the higher level system for managing library sets ("gem sets").

This realease also renames the package name from `roll` to `rolls`.
It's rolls off the tounge better ;)

Changes:

* Spin-off Library and Library::Ledger classes.
* Rename gem from `roll` to `rolls`.


## 1.2.0 / 2010-06-15

This release gets roll command working and improves
the reliability of the system as a whole, including making
metadata lookup more consistant (hint: you want a PACKAGE file).
It is even partially compatible with Gem stores now (exceptions
being loadpaths other than lib/ and the use of autoload).

Changes:

* Reworked metadata system (in line with evolving POM).
* Improved search heuristics (usually much faster now).


## 1.1.0 / 2010-03-01

This release fix a few bugs and makes a few adjustments,
but mostly cleans up code behind the scenes.

Changes:

* Fix incorrect multi-match and absolute path lookup
* Support for Rubinius RUBY_IGNORE_CALLERS


## 1.0.0 / 2010-02-11

This release overhauls the underlying system, which is now very
fast. It supports customizable library environments, and banashes
all traces of package management to the domain of other tools.

Changes:

* Overhauled the entire underlying system.
* Start-up time is blazing fast, loading's is pretty good too.
* Metadata uses POM standard, although not dependent (yet?).
* Environments provide selectable sets of available libraries.


## 0.9.4 / 2008-06-05

The .roll file is no longer used. Instead Rolls is now
using a VERSION file combined with meta/ entries for
loadpath and dependencies (ie. requires).

Changes:

* VERSION and meta/ entries are used instead of '.roll'.


## 0.9.3 / 2007-02-10

Changes:

* Change roll file format and name. It is now .roll.
* Relative require with #use should now work.


## 0.9.2 / 2007-12-17

Changes:

* Changed roll file format from ROLLRC to {name}.roll.
* The name change enabled an order of magnitude increase in startup time!


## 0.9.1 / 2007-11-27

Changes:

* Standard metadate file is now ROLLRC.
* Improved parsing of ROLLRC file, #release is now a Time object.


## 0.9.0 / 2007-11-12

Changes:

* Removed Roll namespace. Library and VersionNumber are now in toplevel.
* Fixed spelling of 'version' in Library#<=>.
* Kernel#require and load now route to Library meta-methods.
* @roll and related methods have been renamed to @package.
* Reduced scan glob to single pattern. Scanning is over 3x faster!

