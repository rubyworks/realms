# TITLE:
#
#   Require / Load Module Extensions
#
# SUMMARY:
#
#   In module require and load.
#
# AUTHORS:
#
#   - Thomas Sawyer

class Module

  # Load file into module/class namespace.

  def module_load( path )
    if path =~ /^[\/~.]/
      file = File.expand_path(path)
    else
      $LOAD_PATH.each do |lp|
        file = File.join(lp,path)
        break if File.exist?(file)
        file = nil
      end
    end

    raise LoadError, "unknown file -- #{path}" unless file

    module_eval(File.read(file))
  end

  # Require file into module/class namespace.

  def module_require( path )
    if path =~ /^[\/~.]/
      file = File.expand_path(path)
    else
      $LOAD_PATH.each do |lp|
        file = File.join(lp,path)
        break if File.exist?(file)
        file += '.rb'
        break if File.exist?(file)
        file = nil
      end
    end

    raise LoadError, "unknown file -- #{path}" unless file

    @loaded ||= {}
    if @loaded.key?(file)
      false
    else
      @loaded[file] = true
      script = File.read(file)
      module_eval(script)
      true
    end
  end
end


class Class
  alias_method :class_load, :module_load
  alias_method :class_require, :module_require
end

