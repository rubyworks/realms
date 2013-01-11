require 'yaml'  # TODO: replace with JSON or Marshal?
require 'json'
require 'rbconfig'
#require 'autoload'
require 'versus'

require 'realms/index'
require 'realms/core_ext'
require 'realms/console'
require 'realms/utils'
require 'realms/errors'
require 'realms/library'
require 'realms/metadata'
require 'realms/version'
require 'realms/ledger'

#require 'realms/shell'

$LEDGER = Rolls::Ledger.new
$LOAD_STACK = []
#$LOAD_CACHE = {}
$SCOPED_FEATURES = Hash.new{ |h,k| h[k] = [] }
$HOLD_PATH = $LOAD_PATH.dup

module Realms
  extend Console
  # Should this be here? Or just in `olls.rb`?
  bootstrap!
end

