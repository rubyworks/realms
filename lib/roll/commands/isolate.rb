module Roll

  # Create an isolation index.
  class CommandIsolate < Command

    #
    def setup
      op.banner = "Usage: roll isolate"
      op.separator "Create an project isolation index."
      op.on('--all', '-a', "Search all environments.") do
        opts[:all] = true
      end
    end

    #
    def call
      if file.directory?(File.join(location, '.ruby'))
        generate_isolate_index
      else
        $stderr.puts "Current directory is not a Ruby project."
      end
    end

    #
    def location
      Dir.pwd
    end

    # TODO: Load in all environments if +all+ option.
    def generate_isolate_index
      if opts[:all]
        list = Library.environments
      else
        list = [Library.environment]
      end

      library = Library.new(location)

      results = library.requirements.verify

      fails, libs = results.partition{ |r| Array === r }

      if fails.empty?
        out = ''
        results.each do |lib|
          out << "%s %s %s\n" % [lib.name, lib.location, lib.loadpath.join(' ')]
        end
        File.open('.ruby/index', 'w'){ |f| f << out }
        puts out
      else
        puts "These libraries could not be found in the current environment:"
        fails.each do |name, vers|
          $stderr.puts "  #{name} #{vers}"
        end
      end
    end

  end

end

