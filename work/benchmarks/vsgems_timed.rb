require 'open3'

$bench_env = File.dirname(__FILE__) + '/rubygems.roll'

def time(cmd)
  cmd = %[export RUBYENV="#{$bench_env}"; export RUBYOPT=""; ] + cmd 
  t = Time.now
  Open3.popen3(cmd) do |stdin, stdout, stderr|  
    puts stdout unless stdout.read.empty?
    puts stderr unless stderr.read.empty?
  end
  Time.now - t
end

# primers
time_gems_req = time %[ruby -rubygems -e'nil']
time_roll_req = time %[ruby -roll -e'nil']

time_gems_use = time %[ruby -rubygems -e'require "facets"']
time_roll_use = time %[ruby -roll -e'require "facets"']

# real
time_gems_req = time %[ruby -rubygems -e'nil']
time_roll_req = time %[ruby -roll -e'nil']

time_gems_use = time %[ruby -rubygems -e'require "facets"']
time_roll_use = time %[ruby -roll -e'require "facets"']

time_gems_load = time_gems_use - time_gems_req
time_roll_load = time_roll_use - time_roll_req

puts "              %-16s %-16s" % [ 'Roll', 'Gems' ]
puts "REQUIRE :     %-16s %-16s" % [ time_roll_req, time_gems_req ]
puts "UTILIZE :     %-16s %-16s" % [ time_roll_load, time_gems_load ]
puts "COMBINED:     %-16s %-16s" % [ time_roll_use, time_gems_use ]
