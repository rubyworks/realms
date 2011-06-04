module Roll

  #
  class CommandIn < Command

    #
    def setup
      op.banner = "Usage: roll in [PATH]"
      op.separator "Insert path into current environment."
      op.separator "Options:"
      op.on("--depth", "-d INTEGER") do |int|
        opts[:depth] = int
      end
      op.on("--live", "-l") do |val|
        opts[:live] = val
      end
    end

    #
    def call
      path  = File.expand_path(args.first || Dir.pwd)
      depth = opts[:depth]
      live  = opts[:live]
      path, file = *Library::Environment.insert(path, depth, live)
      puts "#{path}"
      puts "  '-> #{file}"
    end

  end
end

