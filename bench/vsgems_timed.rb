require 'open3'

def time(cmd)
  cmd = %[export RUBYENV="rubygems"; export RUBYOPT=""; ] + cmd 
  t = Time.now
  Open3.popen3(cmd) do |stdin, stdout, stderr|  
    puts stdout unless stdout.read.empty?
    puts stderr unless stderr.read.empty?
  end
  Time.now - t
end

time_gems_opt = time %[ruby -rubygems -e'nil']
time_roll_opt = time %[ruby -roll -e'nil']

time_gems_req = time %[ruby -e'require "rubygems"']
time_roll_req = time %[ruby -e'require "roll"']

time_gems_use = time %[ruby -e'require "rubygems"; require "facets"']
time_roll_use = time %[ruby -e'require "roll"; require "facets"']

puts "              %-16s %-16s" % [ 'Roll', 'Gems' ]
puts "RUBYOPT :     %-16s %-16s" % [ time_roll_opt, time_gems_opt ]
puts "REQUIRE :     %-16s %-16s" % [ time_roll_req, time_gems_req ]
puts "UTILIZE :     %-16s %-16s" % [ time_roll_use, time_gems_use ]

