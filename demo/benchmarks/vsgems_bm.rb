require 'benchmark'

puts "Ruby Roll"

Benchmark.bmbm do |x|
  x.report("Reqiure Roll: ") { system "ruby -roll -e'nil'" }
  x.report("Require Facets via Roll: ") { system %[export RUBYOPT=""; ruby -roll -e'require "facets"'] }
end

puts; puts
puts "RubyGems"

Benchmark.bmbm do |x|
  x.report("Require Gems: ") { system "ruby -rubygems -e'nil'" }
  x.report("Require Facets via Gems: ") { system %[export RUBYOPT=""; ruby -rubygems -e'require "facets"'] }
end

