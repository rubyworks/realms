require_relative 'helper'

describe Realms::Library::Manager do

  describe "$LOAD_MANAGER" do

    before do
      Library::Utils.reset!
    end

    it "lists the library names via #keys" do
      assert $LOAD_MANAGER.keys.sort == ['foo', 'ruby', 'tryme']
    end

    it "is delegated to by Library.names" do
      assert Realms::Library.names == $LOAD_MANAGER.keys
    end

    it "reduces a list of library version to one when activated" do
      assert $LOAD_MANAGER['tryme'].is_a?(Array)

      library('tryme')

      assert $LOAD_MANAGER['tryme'].is_a?(Realms::Library)
    end

  end

end

