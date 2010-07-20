#require 'roll/monitor'
require 'roll/original'
require 'roll/config'
require 'roll/version'
require 'roll/environment'
require 'roll/library'
require 'roll/ruby'
require 'roll/bootstrap'

Library.bootstrap

module ::Kernel

  # In which library is the current file participating?
  def __LIBRARY__
    $LOAD_STACK.last
  end

  # Activate a library.
  # Same as #library_instance but will raise and error if the library is
  # not found. This can also take a block to yield on the library.
  def library(name, constraint=nil, &block) #:yield:
    Library.activate(name, constraint, &block)
  end

  module_function :library

  # Load script.
  def require(file, options={}, &block)
    Library.require(file, options, &block)
  end

  #
  module_function :require

  # Load script.
  def load(file, options={}, &block)
    Library.load(file, options, &block)
  end

  module_function :load

end

=begin
class Module
  # Autoload script.
  #
  # NOTE: Rolls has to neuter this functionality b/c og a "bug" in Ruby
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

