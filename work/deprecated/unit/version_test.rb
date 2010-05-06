require 'roll/version'
require 'test/unit'

class TestVersion < Test::Unit::TestCase

  #def initialize(*args)
  #  args = args.join('.').split(/\W+/)
  #  @self = args.collect { |i| i.to_i }
  #end

  def test_to_s
    v = Roll::Version.new('1.2.3')
    assert_equal('1.2.3', v.to_s)
  end

  def test_to_str
    v = Roll::Version.new('1.2.3')
    assert_equal('1.2.3', v.to_str)
  end

  #def test_inspect
  #  v = Roll::Version.new('1.2.3')
  #  assert_equal('1.2.3', v.inspect)
  #end

  def test_op_fetch
    v = Roll::Version.new('1.2.3')
    assert_equal(1, v[0])
    assert_equal(2, v[1])
    assert_equal(3, v[2])
  end

  def test_spaceship
    v1 = Roll::Version.new('1.2.3')
    v2 = Roll::Version.new('1.2.4')
    assert_equal(1, v2 <=> v1)
  end

#   def =~( other )
#     #other = other.to_t
#     upver = other.dup
#     upver[0] += 1
#     @self >= other and @self < upver
#   end

  def test_pessimistic
    v1 = Roll::Version.new('1.2.4')
    v2 = Roll::Version.new('1.2')
    assert_equal(true, v1 =~ v2)
  end

  def test_major
     v = Roll::Version.new('1.2.3')
    assert_equal(1, v.major)
  end

  def test_minor
     v = Roll::Version.new('1.2.3')
    assert_equal(2, v.minor)
  end

  def test_teeny
     v = Roll::Version.new('1.2.3')
    assert_equal(3, v.teeny)
  end

  def test_parse_constraint
    assert_equal(["=~", Roll::Version['1.0.0']], Roll::Version.parse_constraint("~> 1.0.0"))
  end

end
