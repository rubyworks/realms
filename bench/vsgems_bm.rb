require 'open3'
require 'benchmark'

def run(cmd)
  Open3.popen3(cmd) do |stdin, stdout, stderr|  
    puts stdout unless stdout.read.empty?
    puts stderr unless stderr.read.empty?
  end
end

puts "RubyGems"

Benchmark.bm(25) do |x|
  x.report("Require Gems:            "){ run %[export RUBYOPT=""; ruby -rubygems -e'nil'] }
  x.report("Require Facets via Gems: "){ run %[export RUBYOPT=""; ruby -rubygems -e'require "facets"'] }
end

puts
puts "Ruby Roll"

Benchmark.bm(25) do |x|
  x.report("Reqiure Roll:            "){ run %[export RUBYOPT=""; ruby -roll -e'nil'] }
  x.report("Require Facets via Roll: "){ run %[export RUBYOPT=""; ruby -roll -e'require "facets"'] }
end

