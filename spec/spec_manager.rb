describe Realms::Library::Manager do

  describe "$LOAD_MANAGER" do

    it "lists the library names via #keys" do
      $LOAD_MANAGER.keys.assert == ['foo', 'ruby', 'tryme']
    end

    it "is delegated to by Library.names" do
      Realms::Library.names.assert == $LOAD_MANAGER.keys
    end

  end

end

