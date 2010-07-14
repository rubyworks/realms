require 'roll/original'
require 'roll/ledger'

# Should this be global constant instead?
$LEDGER = Roll::Ledger.new

module ::Kernel
  # In which library is the current file participating?
  def __LIBRARY__
    #Roll::Library.ledger.load_stack.last
    $LEDGER.load_stack.last
  end

  # Activate a library.
  def library(name, constraint=nil)
    #Roll::Library.ledger.open(name, constraint)
    $LEDGER.open(name, constraint)
  end

  module_function :library

  # Activate a library.
  # TODO: Do we really want a #roll method?
  def roll(name, constraint=nil)
    #Roll::Library.ledger.open(name, constraint)
    $LEDGER.open(name, constraint)
  end

  module_function :roll

  # Require script.
  def require(file)
    #Roll::Library.ledger.require(file)
    $LEDGER.require(file)
  end

  module_function :require

  # Load script.
  def load(file, wrap=false)
    #Roll::Library.ledger.load(file, wrap)
    $LEDGER.load(file, wrap)
  end

  module_function :load

  # Autoload script (Note that rolls neuters this functionality).
  def autoload(constant, file)
    #Roll::Library.ledger.autoload(constant, file)
    $LEDGER.autoload(constant, file)
  end

  module_function :autoload

  # Acquire script.
  def acquire(file, opts={})
    #Roll::Library.ledger.acquire(file, opts)
    $LEDGER.acquire(file, opts)
  end

  module_function :acquire
end

class Module
  # Autoload script.
  #
  # NOTE: Rolls has to neuter this functionality b/c og a "bug" in Ruby
  # which doesn't allow autoload from using overridden require methods.
  def autoload(constant, file)
    #Roll::Library.ledger.autoload(constant, file)
    $LEDGER.autoload(constant, file)
  end

  # Autoload script.
  #
  # NOTE: Rolls has to neuter this functionality b/c og a "bug" in Ruby
  # which doesn't allow autoload from using overridden require methods.
  def self.autoload(constant, file)
    #Roll::Library.ledger.autoload(constant, file)
    $LEDGER.autoload(constant, file)
  end
end

