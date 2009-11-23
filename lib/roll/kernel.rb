require 'roll/library'

module ::Kernel

  # In which library is this file participating?
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

  # Load script.
  def load(file, wrap=false)
    Roll::Library.load(file, wrap)
  end

  # Acquire script.
  def acquire(file, opts={})
    Roll::Library.acquire(file, opts)
  end

end

