require 'open3'
require 'benchmark'

def run(cmd)
  Open3.popen3(cmd) do |stdin, stdout, stderr|  
    out = stdout.read
    err = stderr.read
    puts out unless out.empty?
    puts err unless err.empty?
  end
end

run %[export RUBY_LIBRARY="$GEM_PATH"; export RUBYOPT="-rolls"; ruby -e'require "nokogiri"']

