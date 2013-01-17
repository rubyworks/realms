require 'fileutils'
require 'rbconfig'
#require 'tmpdir'
require 'yaml'
require 'json'
require 'versus'
require 'autoload'

require 'realms/index'
require 'realms/core_ext'
require 'realms/utils'
require 'realms/errors'
require 'realms/library'
require 'realms/interface'
require 'realms/metadata'
require 'realms/manager'
require 'realms/rubylib'
#require 'realms/shell'

#
# Global load manager tracks available libraries and handles all loading.
#
$LOAD_MANAGER = Realms::Library::Manager.new

#
# When a library is being loaded from it will be pushed onto the load stack,
# and popped off when finished.
#
$LOAD_STACK = []

#
# Special #acquire feature allows scripts to be evaled into the context
# of a module or class. This table makes sure it can only ever happen once.
#
$LOADED_SCOPE_FEATURES = Hash.new{ |h,k| h[k] = [] }

#
# Top namespace for Realms, primarily it only contains the Library class.
# All other supporting classes and modules are within the Library class.
# This makes it a clean toplevel include.
#
# @example
#   include Realms
#
module Realms
  #extend Library::ClassInterface

  # Should this be here? Or just in `olls.rb`?
  Library::Utils.bootstrap!
end

