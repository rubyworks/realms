require_relative 'helper'

describe Realms::Library do

  let(:tryme10){ Realms::Library.new('projects/tryme/1.0') }
  let(:tryme11){ Realms::Library.new('projects/tryme/1.1') }

  it "should initialize given the location of a project" do
    assert tryme10.kind_of?(Realms::Library)
  end

  it "should provide access to basic metadata" do
    assert tryme10.name == "tryme"
    assert tryme11.name == "tryme"

    assert tryme10.version.to_s == "1.0"
    assert tryme11.version.to_s == "1.1"
  end

  it "should provide secondary metadata from a `.index` or `.gemspec` file via #[]" do
    #tryme10.metadata['resources']['homepage'].assert == "http://tryme.foo"
    #tryme11.metadata['resources']['homepage'].assert == "http://tryme.foo"
  end

  it "should load scripts from the library" do
    tryme10.load('tryme.rb')

    assert $tryme_message == "Try Me v1.0"

    #assert_raises(Realms::Library::VersionConflict) do
    #  tryme11.load('tryme.rb')
    #end
  end

  it "should require scripts from the library" do
    tryme10.require('tryme')

    assert $tryme_message == "Try Me v1.0"

    # different version will raise an error
    assert_raises(Realms::Library::VersionConflict) do
      tryme11.load('tryme.rb')
    end

    # same version can be required again
    tryme10.require('tryme')
 
    # bypass this constraint using :force option
    tryme11.require('tryme', :force=>true)
    assert $tryme_message == "Try Me v1.1"
  end

end

