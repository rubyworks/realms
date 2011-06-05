= Version Class

Rolls has a versioj class which it uses to compare
versions via vairous constraints.

Load the library.

  require 'roll/version'

First, a version object will return the string representation
via #to_s.

  v = Roll::Version.new('1.2.3')
  '1.2.3'.assert == v.to_s

It will also do this for #to_str.

  v = Roll::Version.new('1.2.3')
  '1.2.3'.assert == v.to_str

The actual segments of a version are stored in an array.
We can access those via #[].

  v = Roll::Version.new('1.2.3')
  1.assert == v[0]
  2.assert == v[1]
  3.assert == v[2]

In addition certain segmetns have special names.
The first is accessible via #major.

  v = Roll::Version.new('1.2.3')
  v.major.assert == 1

The second is accessible via #minor.

  v = Roll::Version.new('1.2.3')
  v.minor.assert == 2

The third is accessible via #patch.

  v = Roll::Version.new('1.2.3')
  v.patch.assert == 3

And lastly anything beyond the patch number is accessible
via #build.

  v = Roll::Version.new('1.2.3.pre.1')
  v.build.assert == 'pre.1'

Two version can be compared with the #<=> method, which
importantly also makes lists of versions sortable.

  v1 = Roll::Version.new('1.2.3')
  v2 = Roll::Version.new('1.2.4')
  (v2 <=> v1).assert == 1

While #=~ provides *pessimistic* constraint comparison.

  v1 = Roll::Version.new('1.2.4')
  v2 = Roll::Version.new('1.2')
  assert(v1 =~ v2)

The Version class also provides some useful singleton methods
such as #parse_constraint. This method deciphers a comparision string.

  a = Roll::Version.parse_constraint("~> 1.0.0")
  e = ["=~", Roll::Version['1.0.0']]
  a.assert == e

Equality can be written with `==` or `=`.

  a = Roll::Version.parse_constraint("= 0.9.0")
  e = ["==", Roll::Version['0.9.0']]
  a.assert == e

Without an operator equality is implied.

  a = Roll::Version.parse_constraint("1.1")
  e = [ "==", Roll::Version['1.1'] ]
  a.assert == e

This is usefuly for parsing requirement configurations. Using it, the Version
class can build contraint comparison procedures.

  compare = Roll::Version.constraint_lambda("=1.0")
  compare.call('1.0').assert == true
  compare.call('0.9').assert == false

Greater than

  compare = Roll::Version.constraint_lambda(">1.0")
  compare.call('1.1').assert == true
  compare.call('0.9').assert == false

Less than

  compare = Roll::Version.constraint_lambda("<1.0")
  compare.call('1.1').assert == false
  compare.call('0.9').assert == true

