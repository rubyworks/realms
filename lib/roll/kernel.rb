module ::Kernel

  # Activate a library.
  def roll(name, constraint=nil)
    Roll.open(name, constraint)
  end

  module_function :roll

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

end

