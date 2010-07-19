abort "Remove -roll from RUBYOPT before running these tests." if ENV['RUBYOPT'].index('-roll')

ENV['XDG_CONFIG_HOME'] = "tmp/config"
ENV['XDG_CACHE_HOME']  = "tmp/cache"
ENV['RUBYENV']                = nil
ENV['roll_environment']       = nil
ENV['roll_environment_stack'] = nil

# Make sure we use local version of files.
$:.unshift('lib')

# redirect config store locations
#require 'roll/config'
#Roll::Config::ROLL_CONFIG_HOME.replace(File.expand_path('tmp/config/roll'))
#Roll::Config::ROLL_CACHE_HOME.replace(File.expand_path('tmp/cache/roll'))

# reset ledger
#$LEDGER = Roll::Ledger.new

#
require 'roll/config'

class Roll::Config
  # redirect local lookup
  def local_directory
    'tmp/local'
  end
end

# okay now we can require roll
require 'roll'
require 'roll/command'

# let's do some pre-start checks

path = File.expand_path('tmp/config/roll/environments')

unless Roll::Environment.home == path
  abort "Starting with incorrect roll environment home\n  #{Roll::Environment.home}\n  #{path}"
end

unless Roll::Environment.default == 'production'
  abort "Starting with incorrect default"
end

env = Roll::Environment.new

abort "Starting with non-default environment (#{env.name})" unless env.name == 'production'
#abort "Starting with non-empty environment" unless env.size == 0

