abort "Remove -roll from RUBYOPT before running tests." if ENV['RUBYOPT'].index('-roll')

ENV['RUBYENV'] = nil
ENV['roll_environment'] = nil
ENV['roll_environment_stack'] = nil

require 'fileutils'

# Make sure we use local version of files.
$:.unshift('lib')

# redirect config store locations
FileUtils.mkdir_p('tmp/config')
FileUtils.mkdir_p('tmp/cache')

require 'roll/config'
::Config::CONFIG_HOME.replace(File.expand_path('tmp/config'))
::Config::CACHE_HOME.replace(File.expand_path('tmp/cache'))

# reset ledger
#$LEDGER = Roll::Ledger.new

# okay now we can require roll
require 'roll'
require 'roll/command'

# let's do some pre-start checks

abort "Not using temporary config location" unless ::Config::CONFIG_HOME == File.expand_path('tmp/config')
abort "Not using temporary cache location" unless ::Config::CACHE_HOME == File.expand_path('tmp/cache')

env = Roll::Environment.new

unless Roll::Environment::HOME == File.expand_path('tmp/config/roll/environments')
  abort "Starting with incorrect HOME -- #{Roll::Environment::HOME}"
end

unless Roll::Environment::DEFAULT_FILE == File.expand_path('tmp/config/roll/default')
  abort "Starting with incorrect DEFAULT_FILE -- #{Roll::Environment::DEFAULT_FILE}"
end

abort "Starting with incorrect default" unless Roll::Environment::DEFAULT == 'production'
abort "Starting with non-default environment (#{env.name})" unless env.name == 'production'
abort "Starting with non-empty environment" unless env.size == 0

# Override shell operator to internal roll command.
# TODO: capture stdout and stderr.
def `(cmd)    #` for highlighter
  case cmd
  when /^roll\ use\ (.*?)$/
    $LEDGER = Roll::Ledger.new($1.strip)  # pretty crazy, but should be ok for testing
  when /^roll/
    cmd  = cmd.sub('roll', '').strip
    argv = *Shellwords.shellwords(cmd)
    out, err = capture do
      Roll::Command.main(*argv)
    end
    out.rewind; err.rewind
    @stdout, @stderr = out.read, err.read
    return @stdout
  else
    super(cmd)
  end
end

