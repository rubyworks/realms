require 'roll/library_class'

module ::Kernel

  # In which library is this file participating?

  def __LIBRARY__
    Library.load_stack.last
  end

  # Activate a library.

  def library(name, constraint=nil)
    Library.open(name, constraint)
  end
  module_function :library

  # Utilize library. This activates a library and adds
  # it's load paths to current library's.

  def utilize(name, constraint=nil)
    Library.open(name, constraint).utilize
  end

  # Require script.

  def require(file)
    Library.require(file)
  end

  # Load script.

  def load(file, wrap=false)
    Library.load(file, wrap)
  end

end

