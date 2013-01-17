When "given an empty cache" do
  ledger = Realms::Library::Utils.lock_file
  File.open(ledger, 'w'){ |f| f <<  '{}' }
end

