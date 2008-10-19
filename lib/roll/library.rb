require 'roll/loadpath'
require 'roll/config'
require 'roll/version'
#require 'roll/sign'

require 'roll/library/constants'
require 'roll/library/metaclass'
require 'roll/library/instance'
require 'roll/library/kernel'

# Prime the library ledger.
Library.setup
#Library.load_cache

# TODO: With Reap available, we can have rich package metadata.
#begin ; require 'reap:project' ; rescue LoadError ; end

