require 'rbconfig'
require 'autoload'
require 'library'

require 'rolls/index'
require 'rolls/utils'
require 'rolls/ledger'
require 'rolls/console'
#require 'rolls/shell'

$LEDGER = Rolls::Ledger.new
$LOAD_STACK = []
$LOAD_CACHE = {}

module Rolls
  extend Console
  # Should this be here? Or just in `olls.rb`?
  bootstrap!
end

