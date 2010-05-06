# Rubinius
RUBY_IGNORE_CALLERS = [] unless defined? RUBY_IGNORE_CALLERS
RUBY_IGNORE_CALLERS << %r{roll/kernel\.rb$}
RUBY_IGNORE_CALLERS << %r{roll/original\.rb$}
 
module ::Kernel
  alias_method :original_require, :require
  alias_method :original_load, :load
end

