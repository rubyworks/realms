class Hash

  #
  def rekey #:yield:
    if block_given?
      inject({}){|h,(k,v)| h[yield(k)]=v; h}
    else
      inject({}){|h,(k,v)| h[k.to_sym]=v; h}
    end
  end

  #
  def rekey! #:yield:
    replace(rekey{|k| yield(k) })
  end

end
