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

run %[export RUBYENV="rubygems"; export RUBYOPT=""; ruby -roll -e'require "nokogiri"']

