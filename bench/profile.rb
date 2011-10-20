require 'open3'
require 'profile'

$bench_env = File.dirname(__FILE__) + '/rubygems.roll'

def run(cmd)
  cmd = %[export RUBYENV="#{$bench_env}"; export RUBYOPT=""; ] + cmd 
  Open3.popen3(cmd) do |stdin, stdout, stderr|  
    out = stdout.read
    err = stderr.read
    puts out unless out.empty?
    puts err unless err.empty?
  end
end

run %[ruby -rprofile -roll -e'require "facets"']

