module Roll

  #
  class CommandOut < Command

    #
    def setup
      op.banner = "Usage: roll out [PATH]"
      op.separator "Remove path from current environment."
    end

    #
    def call
      path = File.expand_path(args.first || Dir.pwd)
      path, file = *Roll::Environment.remove(path)
      puts "#{file}"
      puts "  '-> #{path} -> [x]"
    end

  end

end
