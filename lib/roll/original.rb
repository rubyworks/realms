# Rubinius
RUBY_IGNORE_CALLERS = [] unless defined? RUBY_IGNORE_CALLERS
RUBY_IGNORE_CALLERS << %r{roll/kernel\.rb$}
RUBY_IGNORE_CALLERS << %r{roll/original\.rb$}

module ::Kernel
  alias_method :roll_original_require, :require
  alias_method :roll_original_load, :load

  alias_method :autoload_without_rolls, :autoload
end

class ::Module
  alias_method :autoload_without_rolls, :autoload
end

