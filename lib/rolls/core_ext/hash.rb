class Hash

  #
  # Transform keys of hash returning a new hash.
  #
  def rekey #:yield:
    if block_given?
      inject({}){|h,(k,v)| h[yield(k)]=v; h}
    else
      inject({}){|h,(k,v)| h[k.to_sym]=v; h}
    end
  end

  #
  # In-place rekey.
  #
  def rekey! #:yield:
    replace(rekey{|k| yield(k) })
  end

end

