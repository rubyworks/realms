require 'benchmark'
require 'csv'
require 'yaml'
require 'json'
require 'tmpdir'

count = 1000

file = Dir.tmpdir + "/roll-benchmark-file"

data = [
  ["row1", "of", "CSV", "data"],
  ["row2", "of", "CSV", "data"],
  ["row3", "of", "CSV", "data"],
  ["row4", "of", "CSV", "data"]
]

Benchmark.bm(25) do |x|
  x.report("  File Write:            ") do
    count.times do
      File.open(file + '.txt', "w") do |csv|
        data.each do |row|
          csv << row.inspect
        end
      end
    end
  end

  x.report("  File Read:             ") do
    count.times do
      array = []
      File.readlines(file + '.txt').each do |line|
        line = line.strip.chomp('"').sub(/^\"/,'')
        next if line.empty?
        next if line =~ /^#/
        row = line.split('","')
        array << row
      end
      array
    end
  end  

  x.report("  CSV Write              ") do
    count.times do
      CSV.open(file + '.cvs', "wb") do |csv|
        data.each do |row|
          csv << row
        end
      end
    end
  end

  x.report("  CSV Read:              ") do
    count.times do
      array = []
      CSV.foreach(file + '.cvs') do |row|
        array << row
      end
      array
    end
  end

  x.report("  Marshal Write:         ") do
    count.times do
      File.open(file + '.marshal', "wb") do |w|
        w << Marshal.dump(data)
      end
    end
  end

  x.report("  Marshal Read:          ") do
    count.times do
      Marshal.load(File.new(file + '.marshal'))
    end
  end

  x.report("  YAML Write:         ") do
    count.times do
      File.open(file + '.yaml', "wb") do |w|
        w << data.to_yaml
      end
    end
  end

  x.report("  YAML Read:          ") do
    count.times do
      YAML.load(File.new(file + '.yaml'))
    end
  end

  x.report("  JSON Write:         ") do
    count.times do
      File.open(file + '.yaml', "wb") do |w|
        w << JSON.dump(data)
      end
    end
  end

  x.report("  JSON Read:          ") do
    count.times do
      JSON.load(File.new(file + '.yaml'))
    end
  end

end

