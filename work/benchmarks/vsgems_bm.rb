require 'open3'
require 'benchmark'

# prime any file system caches
#require 'facets'
#require 'nokogiri'

$bench_env = File.dirname(__FILE__) + '/rubygems.roll'

def run(cmd)
  cmd = %[export RUBY_LIBRARY="#{$bench_env}"; export RUBYOPT=""; ] + cmd 
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
  x.report("  Require Gems:          "){ run %[ruby -rubygems -e'nil'] }
  x.report("  Require Facets:        "){ run %[ruby -rubygems -e'require "facets"'] }
  x.report("  Require Nokogiri:      "){ run %[ruby -rubygems -e'require "nokogiri"'] }
end

puts
puts "Ruby Roll"

Benchmark.bm(25) do |x|
  x.report("  Reqiure Roll:          "){ run %[ruby -rolls -e'nil'] }
  x.report("  Require Facets:        "){ run %[ruby -rolls -e'require "facets"'] }
  x.report("  Require Nokogiri:      "){ run %[ruby -rolls -e'require "nokogiri"'] }
end

puts
