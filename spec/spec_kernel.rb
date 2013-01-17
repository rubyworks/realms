require_relative 'helper'

describe Kernel do

  describe "#library" do

    before do
      Library::Utils.reset!
    end

    it "activates a library, constraining it to a single version" do
      library('tryme', '1.1')

      assert $LOAD_MANAGER['tryme'].class == Library
      assert $LOAD_MANAGER['tryme'].version.to_s == '1.1'
    end

    it "will raise an error if given a conflicting version" do
      library('tryme', '1.1')

      assert_raises(Library::VersionConflict) do
        library('tryme', '1.0')
      end
    end

  end

end

