= Unit Tests for Version Class

Load the library.

  require 'roll/version'

Test #to_s:

  v = Roll::Version.new('1.2.3')
  '1.2.3'.assert == v.to_s

Test #to_str:

  v = Roll::Version.new('1.2.3')
  '1.2.3'.assert == v.to_str

Test #[]:

  v = Roll::Version.new('1.2.3')
  1.assert == v[0]
  2.assert == v[1]
  3.assert == v[2]

Test #<=>:

  v1 = Roll::Version.new('1.2.3')
  v2 = Roll::Version.new('1.2.4')
  1.assert == (v2 <=> v1)

Test #=~ (pessimistic constraint):

  v1 = Roll::Version.new('1.2.4')
  v2 = Roll::Version.new('1.2')
  assert(v1 =~ v2)

Test #major:

  v = Roll::Version.new('1.2.3')
  1.assert == v.major

Test #minor:

  v = Roll::Version.new('1.2.3')
  2.assert == v.minor

Test #teeny:

  v = Roll::Version.new('1.2.3')
  3.assert == v.teeny

Test #parse_constraint:

  a = Roll::Version.parse_constraint("~> 1.0.0")
  e = [ "=~", Roll::Version['1.0.0'] ]
  e.assert == a
