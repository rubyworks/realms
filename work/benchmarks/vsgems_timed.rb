require 'open3'

$bench_env = File.dirname(__FILE__) + '/rubygems.roll'

def time(cmd)
  cmd = %[export RUBY_LIBRARY="#{$bench_env}"; export RUBYOPT=""; ] + cmd 
  t = Time.now
  Open3.popen3(cmd) do |stdin, stdout, stderr|
    out_str = stdout.read
    err_str = stderr.read
    puts out_str unless out_str.empty?
    puts err_str unless err_str.empty?
  end
  Time.now - t
end

# primers
time_gems_req = time %[ruby -rubygems -e'nil']
time_roll_req = time %[ruby -rolls -e'nil']

time_gems_use = time %[ruby -rubygems -e'require "facets"']
time_roll_use = time %[ruby -rolls -e'require "facets"']

# real
time_gems_req = time %[ruby -rubygems -e'nil']
time_roll_req = time %[ruby -rolls -e'nil']

time_gems_use = time %[ruby -rubygems -e'require "facets"']
time_roll_use = time %[ruby -rolls -e'require "facets"']

time_gems_load = time_gems_use - time_gems_req
time_roll_load = time_roll_use - time_roll_req

puts "              %-16s %-16s" % [ 'Rolls', 'Gems' ]
puts "REQUIRE :     %-16.8f %-16.8f" % [ time_roll_req, time_gems_req ]
puts "UTILIZE :     %-16.8f %-16.8f" % [ time_roll_load, time_gems_load ]
puts "COMBINED:     %-16.8f %-16.8f" % [ time_roll_use, time_gems_use ]
