require 'open3'

def time(cmd)
  t = Time.now
  Open3.popen3(cmd) do |stdin, stdout, stderr|  
    puts stdout unless stdout.read.empty?
    puts stderr unless stderr.read.empty?
  end
  Time.now - t
end

time_gems_opt = time %[export RUBYOPT=""; ruby -rubygems -e'nil']
time_roll_opt = time %[export RUBYOPT=""; ruby -roll -e'nil']

time_gems_req = time %[export RUBYOPT=""; ruby -e'require "rubygems"']
time_roll_req = time %[export RUBYOPT=""; ruby -e'require "roll"']

time_gems_use  = time %[export RUBYOPT=""; ruby -e'require "rubygems"; require "facets"']
time_roll_use = time %[export RUBYOPT=""; ruby -e'require "roll"; require "facets"']

puts "              %-16s %-16s" % [ 'Roll', 'Gems' ]
puts "RUBYOPT :     %-16s %-16s" % [ time_roll_opt, time_gems_opt ]
puts "REQUIRE :     %-16s %-16s" % [ time_roll_req, time_gems_req ]
puts "UTILIZE :     %-16s %-16s" % [ time_roll_use, time_gems_use ]



