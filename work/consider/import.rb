# Python-like +import+ support.
# (or should we use Perl's +use+ instead?)
#
# TODO Feature starting with './' should be loaded from => dirname(__FILE__).
# TODO Intergrate w/ "Rolls" (versioning, metadata, Library class, etc.)

class Module

  def import( feature, opts={} )
    if from = opts[:from]
      file = lookup_feature(File.join(from,feature))
    else
      file = lookup_feature(feature)
    end

    namespace = feature.split('/').collect{|name|name.capitalize}

    mod = namespace.inject(Object) do |parent,name|
      if parent.const_defined?(name)
        parent.const_get(name)
      else
        parent.const_set(name, Module.new)
      end
    end

    mod.module_eval File.read(file)
    mod.extend mod
    mod
  end

  def new(*a,&b)
    aspect.new(*a,&b)
  end

  def aspect
    @aspect_ ||= Class.new{include self}
  end

  def lookup_feature( feature, load_path=$LOAD_PATH )
    feature = feature.to_s
    search = '{'+load_path.join(',')+'}/'+feature.to_s+'.rb'
    files = Dir.glob(search)
    file = files[0]
    return file
  end

  #def const_missing(const)
  #  if Object == self
  #    feature = "#{const}".gsub('::','/').downcase
  #  else
  #    feature = "#{self}::#{const}".gsub('::','/').downcase
  #  end
  #  file = lookup_feature(feature)
  #  if file
  #    import feature
  #  else
  #    const_set(const, Module.new)
  #  end
  #end

end


class Object

  def import(*a)
    Object.import(*a)    
  end

end


if __FILE__ == $0

  import 'demo', :from => 'demo'

  Demo.hello

end

