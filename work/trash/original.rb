# TODO: Make a global variable
RUBY_IGNORE_CALLERS = [] unless defined? RUBY_IGNORE_CALLERS
RUBY_IGNORE_CALLERS << %r{roll/kernel\.rb$}
RUBY_IGNORE_CALLERS << %r{roll/original\.rb$}

module ::Kernel
  class << self
    alias_method :require_without_rolls, :require
    alias_method :load_without_rolls, :load
  end

  alias_method :require_without_rolls, :require
  alias_method :load_without_rolls, :load
  #alias_method :autoload_without_rolls, :autoload
end

#class ::Module
#  alias_method :autoload_without_rolls, :autoload
#end

