require 'rbconfig'

module Ruby
  extend self

  LOAD_PATH = $LOAD_PATH.dup

  # Dynamic link extension.
  def dlext
    @dlext ||= ::Config::CONFIG['DLEXT']
  end

#   #
#   def require(fname)
#     find = File.join('{' + LOAD_PATH.join(',') + '}', fname + "{.rb,#{DLEXT},}")
#     files = Dir.glob(find)
#     if files.empty?
#       raise LoadError, "no such file to load -- #{fname}"
#     else
#       Kernel.require(files.first)
#     end
#   end
# 
#   #
#   def load(fname, safe=nil)
#     Kernel.load(fname, safe)
#   end

end
