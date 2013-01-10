require 'yaml'  # TODO: replace with JSON or Marshal?
require 'rbconfig'
#require 'autoload'
require 'versus'

require 'rolls/index'
require 'rolls/core_ext'
require 'rolls/console'
require 'rolls/utils'
require 'rolls/errors'
require 'rolls/library'
require 'rolls/metadata'
require 'rolls/version'
require 'rolls/ledger'

#require 'rolls/shell'

$LEDGER = Rolls::Ledger.new
$LOAD_STACK = []
$LOAD_CACHE = {}

module Rolls
  extend Console
  # Should this be here? Or just in `olls.rb`?
  bootstrap!
end

