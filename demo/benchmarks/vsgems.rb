require 'benchmark'

Benchmark.bm do |x|
  x.report("Gems: ") { system "ruby -rubygems -e'nil'" }
  x.report("Roll: ") { system "ruby -roll -e'nil'" }
end

Benchmark.bm do |x|
  x.report("Gems: ") { system %[export RUBYOPT=""; ruby -rubygems -e'require "facets"'] }
  x.report("Roll: ") { system %[export RUBYOPT=""; ruby -roll -e'require "facets"'] }
end

