module ::Kernel
  alias_method :original_require, :require
  alias_method :original_load, :load
end

