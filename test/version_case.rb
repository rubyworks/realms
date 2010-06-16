Covers 'roll/version'

Case Roll::Version do

  Concern "Ensure functionality of Roll's Version class."

  Unit :to_s do
    v = Roll::Version.new('1.2.3')
    v.to_s.assert == '1.2.3'
  end

  Unit :to_str do
    v = Roll::Version.new('1.2.3')
    v.to_str.assert == '1.2.3'
  end

  #def test_inspect
  #  v = Roll::Version.new('1.2.3')
  #  assert_equal('1.2.3', v.inspect)
  #end

  Unit :[] do
    v = Roll::Version.new('1.2.3')
    v[0].assert == 1
    v[1].assert == 2
    v[2].assert == 3
  end

  Unit :<=> do
    v1 = Roll::Version.new('1.2.3')
    v2 = Roll::Version.new('1.2.4')
    (v2 <=> v1).assert == 1
  end

#   def =~( other )
#     #other = other.to_t
#     upver = other.dup
#     upver[0] += 1
#     @self >= other and @self < upver
#   end

  Unit :=~, "pessimistic constraint" do
    v1 = Roll::Version.new('1.2.4')
    v2 = Roll::Version.new('1.2')
    assert(v1 =~ v2)
  end

  Unit :major do
    v = Roll::Version.new('1.2.3')
    v.major.assert == 1
  end

  Unit :minor do
    v = Roll::Version.new('1.2.3')
    v.minor.assert == 2
  end

  Unit :patch do
    v = Roll::Version.new('1.2.3')
    v.patch.assert == 3
  end

  Unit :parse_constraint do
    constraint = Roll::Version.parse_constraint("~> 1.0.0")
    constraint.assert == ["=~", Roll::Version['1.0.0']]
  end

end

