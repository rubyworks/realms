abort "Remove -realms from RUBYOPT before running these tests." if ENV['RUBYOPT'].index('-realms')

$realms_root = File.expand_path(File.dirname(__FILE__) + '/..')

#ENV['XDG_CONFIG_HOME'] = File.join($project_root, "tmp/config")
ENV['XDG_CACHE_HOME'] = File.join($realms_root, "tmp/cache")
ENV['RUBY_LIBRARY']   = File.join($realms_root, "spec/fixtures/projects/*")

# link tmp/projects to spec/fixtures/projects
tmp_projects = File.join($realms_root, 'tmp/projects')
unless File.exist?(tmp_projects)
  require 'fileutils'
  FileUtils.ln_s(File.join($realms_root, 'spec/fixtures/projects'), tmp_projects)
end

# test from within tmp directoy
Dir.chdir('tmp')

# Make sure we use local version of files.
$:.unshift('../lib')

require 'minitap'

require 'realms'
#require 'realms/shell'

# pre-start checks
raise unless Realms::Library::Utils.tmpdir == File.join($realms_root, "tmp/cache/ruby")

# include Realms at top-level for convenience
include Realms

require 'minitest/autorun'
MiniTest::Unit.runner = MiniTest::TapY.new

