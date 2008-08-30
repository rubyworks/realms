
module Kernel

  # Load a library into a specific base module/class.
  # If not base is given the the lib is loaded into
  # the instance class (singleton) or the current object.

  def import( path, base=nil )
    base ||= (class << self; self; end)

    if path =~ /^[\/~.]/
      path = File.expand_path(path)
    else
      $LOAD_PATH.each do |lp|
        file = File.join(lp,path)
        if File.exist?(file)
          path = file
          break
        end
      end
    end

    base.module_eval(File.read(path))
  end

end


class Module

  # Import library into module space.

  def import( path )
    super( path, self )
  end

end
