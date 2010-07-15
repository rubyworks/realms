# Rubinius
RUBY_IGNORE_CALLERS = [] unless defined? RUBY_IGNORE_CALLERS
RUBY_IGNORE_CALLERS << %r{roll/kernel\.rb$}
RUBY_IGNORE_CALLERS << %r{roll/original\.rb$}

module ::Kernel
  alias_method :require_without_rolls, :require

  alias_method :load_without_rolls, :load

  alias_method :autoload_without_rolls, :autoload

  # DEPRECATE
  alias_method :roll_original_require, :require
  alias_method :roll_original_load, :load
end

class ::Module
  alias_method :autoload_without_rolls, :autoload
end

