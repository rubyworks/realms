require 'benchmark'

def load_ruby
  eval(File.read('example.rb'))
end

def load_yaml
  YAML.load(File.new("example.yaml"))
end

def load_json
  JSON.load(File.new("example.json"))
end

def load_files
  data = {}
  #data['name']     = File.read('example/name')
  data['version']  = File.read('example/version')
  #data['loadpath'] = File.read('example/loadpath').strip.split(/\n/)
  data['require']  = File.read('example/loadpath').strip.split(/\n/)
  data
end

count = 10000

puts
puts "Files:"

Benchmark.bm(25) do |x|
  x.report("  Files:          "){ count.times{ load_files } }
end

puts
puts "Ruby:"

Benchmark.bm(25) do |x|
  x.report("  Ruby:          "){ count.times{ load_ruby } }
end

puts
puts "YAML:"

Benchmark.bm(25) do |x|
  x.report("  Require YAML:          "){ require 'yaml' }
end

Benchmark.bm(25) do |x|
  x.report("  YAML:          "){ count.times{ load_yaml } }
end

puts
puts "JSON:"

Benchmark.bm(25) do |x|
  x.report("  Require JSON:          "){ require 'json' }
end

Benchmark.bm(25) do |x|
  x.report("  JSON:          "){ count.times{ load_json } }
end

