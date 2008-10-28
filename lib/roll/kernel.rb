module ::Kernel

  # Activate a library.
  def roll(name, constraint=nil)
    Roll.open(name, constraint)
  end

  module_function :roll

  #
  def require(fname)
    begin
      Kernel.require(fname)
    rescue LoadError => error
      name = fname.split(/[\\\/]/).first
      if Roll.list.include?(name)
        Roll.instance(name).activate
        retry
      else
        raise error
      end
    end
  end

  #
  def load(fname, safe=nil)
    begin
      Kernel.load(fname, safe)
    rescue LoadError => error
      name = fname.split(/[\\\/]/).first
      if Roll.list.include?(name)
        Roll.instance(name).activate
        retry
      else
        raise error
      end
    end
  end

end

