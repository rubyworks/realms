module Roll

  class CommandWhich < Command

    #
    def setup
      op.banner = "Usage: roll which <path>"
      op.separator "Display absolute path of library path."
      #op.on('--all', '-a', "Search all environments.") do
      #  opts[:all] = true
      #end
    end

    #
    def call
      path = args.first
      file = library_find(path)
      if file
        puts file.fullname
      else
        puts "Not found."
      end
    end

  end

end
