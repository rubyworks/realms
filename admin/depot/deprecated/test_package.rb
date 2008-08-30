require 'test/unit'
require 'roll/package'

class TestPacakge1 < Test::Unit::TestCase

  def setup
    @data ||= YAML.load(File.open('test/fixtures/example1.yaml'))
    @info ||= Library::Package.new(@data)
  end

  def test_access
    assert_equal("foo", @info.project)
    assert_equal("foo", @info.name)
    assert_equal("Foo", @info.title)
  end

  def test_location
    assert_equal(nil, @info.file)
    assert_equal(nil, @info.location)
  end

end


class TestPackage2 < Test::Unit::TestCase

  def setup
    @file ||= 'test/fixtures/example1.yaml'
    @info ||= Library::Package.open(@file)
  end

  def test_access
    assert_equal("foo", @info.project)
    assert_equal("foo", @info.name)
    assert_equal("Foo", @info.title)
  end

  def test_location
    file = @file
    #file = File.expand_path(@file)
    assert_equal(file, @info.file)
    assert_equal(File.dirname(file), @info.location)
  end

end
