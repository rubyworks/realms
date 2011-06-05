# TODO: Roll compatible autoload.

=begin
class Module
  # Autoload script.
  #
  # NOTE: Rolls has to neuter this functionality b/c of a "bug" in Ruby
  # which doesn't allow autoload from using overridden require methods.
  def autoload(constant, file)
    #Library.ledger.autoload(constant, file)
    $LEDGER.autoload(constant, file)
  end

  # Autoload script.
  #
  # NOTE: Rolls has to neuter this functionality b/c og a "bug" in Ruby
  # which doesn't allow autoload from using overridden require methods.
  def self.autoload(constant, file)
    #Library.ledger.autoload(constant, file)
    $LEDGER.autoload(constant, file)
  end
end
=end
