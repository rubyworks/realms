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

puts
puts "RubyGems"

Benchmark.bm(25) do |x|
  x.report("  Require Gems:          "){ run %[export RUBYOPT=""; ruby -rubygems -e'nil'] }
  x.report("  Require Facets:        "){ run %[export RUBYOPT=""; ruby -rubygems -e'require "facets"'] }
  x.report("  Require Nokogiri:      "){ run %[export RUBYOPT=""; ruby -rubygems -e'require "nokogiri"'] }
end

puts
puts "Ruby Roll"

Benchmark.bm(25) do |x|
  x.report("  Reqiure Roll:          "){ run %[export RUBYOPT=""; ruby -roll -e'nil'] }
  x.report("  Require Facets:        "){ run %[export RUBYOPT=""; ruby -roll -e'require "facets"'] }
  x.report("  Require Nokogiri:      "){ run %[export RUBYOPT=""; ruby -roll -e'require "nokogiri"'] }
end

puts
