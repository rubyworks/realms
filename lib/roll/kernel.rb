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

  # Require script.
  def require(file)
    Roll::Library.require(file)
  end

  # Load script.
  def load(file, wrap=false)
    Roll::Library.load(file, wrap)
  end


  # Activate a library.
  def roll(name, constraint=nil)
    Roll::Library.open(name, constraint)
  end

  module_function :roll

  # Utilize library. This activates a library and adds
  # it's load paths to current library's.
  #def utilize(name, constraint=nil)
  #  Roll::Library.open(name, constraint).utilize
  #end

=begin
  alias_method :require_without_roll, :require

  #
  def require(fname)
    begin
      require_without_roll(fname)
    rescue LoadError => error
      name = fname.split(/[\\\/]/).first
      if Roll.list.include?(name)
        Roll.instance(name).activate
        require_without_roll(fname)
      else
        raise error
      end
    end
  end

  alias_method :load_without_roll, :load

  #
  def load(fname, safe=nil)
    begin
      load_without_roll(fname, safe)
    rescue LoadError => error
      name = fname.split(/[\\\/]/).first
      if Roll.list.include?(name)
        Roll.instance(name).activate
        load_without_roll(fname, safe)
      else
        raise error
      end
    end
  end
=end

end


