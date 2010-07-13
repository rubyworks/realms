require 'roll/original'

module ::Kernel
  # In which library is the current file participating?
  def __LIBRARY__
    Roll::Library.load_stack.last
  end

  # Activate a library.
  def library(name, constraint=nil)
    Roll::Library.open(name, constraint)
  end

  module_function :library

  # Activate a library.
  def roll(name, constraint=nil)
    Roll::Library.open(name, constraint)
  end

  module_function :roll

  # Require script.
  def require(file)
    Roll::Library.require(file)
  end

  module_function :require

  # Load script.
  def load(file, wrap=false)
    Roll::Library.load(file, wrap)
  end

  module_function :load

  # Autoload script (Note that rolls neuters this functionality).
  def autoload(constant, fname)
    Roll::Library.autoload(constant, fname)
  end

  module_function :autoload

  # Acquire script.
  def acquire(file, opts={})
    Roll::Library.acquire(file, opts)
  end

end

class Module
  # Autoload script (Note that rolls neuters this functionality).
  def autoload(constant, fname)
    Roll::Library.autoload(constant, fname)
  end

  # Autoload script (Note that rolls neuters this functionality).
  def self.autoload(constant, fname)
    Roll::Library.autoload(constant, fname)
  end
end

