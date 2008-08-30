require 'roll/version'
require 'test/unit'

class TestVersionNumber < Test::Unit::TestCase

  #def initialize(*args)
  #  args = args.join('.').split(/\W+/)
  #  @self = args.collect { |i| i.to_i }
  #end

  def test_to_s
    v = VersionNumber.new('1.2.3')
    assert_equal('1.2.3', v.to_s)
  end

  def test_to_str
    v = VersionNumber.new('1.2.3')
    assert_equal('1.2.3', v.to_str)
  end

  #def test_inspect
  #  v = VersionNumber.new('1.2.3')
  #  assert_equal('1.2.3', v.inspect)
  #end

  def test_op_fetch
    v = VersionNumber.new('1.2.3')
    assert_equal(1, v[0])
    assert_equal(2, v[1])
    assert_equal(3, v[2])
  end

  def test_spaceship
    v1 = VersionNumber.new('1.2.3')
    v2 = VersionNumber.new('1.2.4')
    assert_equal(1, v2 <=> v1)
  end

#   def =~( other )
#     #other = other.to_t
#     upver = other.dup
#     upver[0] += 1
#     @self >= other and @self < upver
#   end

  def test_pessimistic
    v1 = VersionNumber.new('1.2.4')
    v2 = VersionNumber.new('1.2')
    assert_equal(true, v1 =~ v2)
  end

  def test_major
     v = VersionNumber.new('1.2.3')
    assert_equal(1, v.major)
  end

  def test_minor
     v = VersionNumber.new('1.2.3')
    assert_equal(2, v.minor)
  end

  def test_teeny
     v = VersionNumber.new('1.2.3')
    assert_equal(3, v.teeny)
  end

  def test_parse_constraint
    assert_equal(["=~", VersionNumber['1.0.0']], VersionNumber.parse_constraint("~> 1.0.0"))
  end

end
