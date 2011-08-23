module Roll

  class CommandWhere < Command

    #
    def setup
      op.banner = "Usage: roll where <script>"
      op.separator "Display absolute path to a script."
      #op.on('--all', '-a', "Search all environments.") do
      #  opts[:all] = true
      #end
    end

    #
    def call
      script = args.first
      path = Library.find(script)
      if path
        $stdout.puts path
      else
        $stderr.puts "Not found."
      end
    end

  end

end
