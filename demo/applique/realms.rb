abort "Remove -realms from RUBYOPT before running these tests." if ENV['RUBYOPT'].index('-realms')

$realms_root = File.expand_path(File.dirname(__FILE__) + '../../..')

#ENV['XDG_CONFIG_HOME'] = File.join($project_root, "tmp/qed/config")
ENV['XDG_CACHE_HOME'] = File.join($realms_root, "tmp/qed/cache")
ENV['RUBY_LIBRARY']   = File.join($realms_root, "demo/fixtures/projects/*")

# Make sure we use local version of files.
$:.unshift('lib')

require 'realms'
#require 'realms/shell'

# let's do some pre-start checks

assert(Realms::Library::Utils.tmpdir == File.join($realms_root, "tmp/qed/cache/ruby"))

