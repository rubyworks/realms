
time_roll_init = `export RUBYOPT=""; ruby -e't=Time.now; require "roll"; puts Time.now - t'`.strip
time_roll_reqs = `export RUBYOPT=""; ruby -e'require "roll"; t=Time.now; require "facets"; puts Time.now - t'`.strip

time_gems_init = `export RUBYOPT=""; ruby -e't=Time.now; require "rubygems"; puts Time.now - t'`.strip
time_gems_reqs = `export RUBYOPT=""; ruby -e'require "rubygems"; t=Time.now; require "facets"; puts Time.now - t'`.strip

puts "      %20s %20s" % [ 'Roll', 'Gems' ]
puts "Init: %20s %20s" % [ time_roll_init, time_gems_init ]
puts "Reqs: %20s %20s" % [ time_roll_reqs, time_gems_reqs ]

