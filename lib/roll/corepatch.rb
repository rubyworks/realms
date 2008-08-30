module ::Kernel

  def metaclass(klass=nil,&block)
    obj  = klass || self
    meta = (class << obj; self; end)
    meta.class_eval(&block)
  end

end

#class ::Module #:nodoc:
#
#  def metaclass(klass=nil,&block)
#    klass ||= self
#    klass.class_eval(&block)
#  end
#
#end

