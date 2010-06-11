module Roll

  #
  class Locals

    include Enumerable

    #
    DIR = XDG.config_home, 'roll', 'locals'

    #
    #def self.save(name)
    #  File.open(file, 'w'){ |f| f << "#{name}" }
    #end

    # List of available environments.
    def self.list
      Dir[File.join(DIR, '*')].map do |file|
        File.basename(file)
      end
    end

    #
    def initialize(name=nil)
      @name = name || self.class.current
      reload
    end

    #
    def name
      @name
    end

    #
    def file
      @file ||= File.join(DIR, name)
    end

    #
    def reload
      t = []
      if File.exist?(file)
        lines = File.readlines(file)
        lines.each do |line|
          line = line.strip
          path, depth = *line.split(/\s+/)
          next if line =~ /^\s*$/  # blank
          next if line =~ /^\#/    # comment
          dir, depth = *line.split(/\s+/)
          t << [path, (depth || 3).to_i]
        end
      else
        t = []
      end
      @table = t
    end

    #
    def each(&block)
      @table.each(&block)
    end

    #
    def size
      @table.size
    end

    #
    def append(path, depth=3)
      path  = File.expand_path(path)
      depth = (depth || 3).to_i
      @table = @table.reject{ |(p, d)| path == p }
      @table.push([path, depth])
    end

    #
    def delete(path)
      @table.reject!{ |p,d| path == p }
    end

    #
    def save
      out = @table.map do |(path, depth)|
        "#{path}   #{depth}"
      end
      dir = File.dirname(file)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      File.open(file, 'w') do |f|
        f <<  out.join("\n")
      end
    end

  end

end

