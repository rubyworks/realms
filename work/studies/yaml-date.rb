module Kernel
  alias_method :old_require, :require
  alias_method :old_load, :load
  alias_method :old_autoload, :autoload

  def require(path)
    p "require: #{path}"
    old_require(path)
  end

  module_function :require

  def load(path, wrap=nil)
    p "load: #{path}"
    old_load(path, wrap)
  end

  module_function :load

  def autoload(constant, path)
    p "autoload: #{path}"
    old_autoload(constant, path)
  end

  module_function :autoload
end


class Module
  alias_method :old_autoload, :autoload

  def autoload(constant, path)
    p "autoload: #{path}"
    old_autoload(constant, path)
  end

  def self.autoload(constant, path)
    p "autoload: #{path}"
    old_autoload(constant, path)
  end
end

# now the test

l1 = $".dup

require 'yaml'

l2 = $".dup
$".clear

puts "LOADING YAML DOCUMENT"

YAML.load <<-HERE
  date: 2010-10-01
HERE

p $" - l2

