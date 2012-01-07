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
      location = args.first || Dir.pwd
      if File.directory?(File.join(location, '.ruby'))
        generate_isolate_index(location)
      else
        $stderr.puts "Directory is not a Ruby project."
      end
    end

    # TODO: Load in all environments if +all+ option as resource for lookup.
    #
    # TODO: Move most of this code into library somewhere.
    def generate_isolate_index(location)
      require 'fileutils'

      #if opts[:all]
      #  list = Roll.environments
      #else
      #  list = [Roll.environment.name]
      #end

      library = Library.new(location)

      results = library.requirements.verify

      fails, libs = results.partition{ |r| Array === r }

      if fails.empty?
        out = ''

        max_name = results.map{ |lib| lib.name.size }.max
        max_path = results.map{ |lib| lib.location.size }.max

        results.each do |lib|
          out << "%-#{max_name}s  %-#{-max_path}s  %s\n" % [lib.name, lib.location, lib.loadpath.join(' ')]
        end

        dir = Roll.config.local_environment_directory

        FileUtils.mkdir_p(dir)

        file = File.join(dir, 'local')

        File.open(file, 'w'){ |f| f << out }

        $stdout.puts out
        $stderr.puts
        $stderr.puts "Saved to `#{file}`."
      else
        puts "These libraries could not be found in the current environment:"
        fails.each do |name, vers|
          $stderr.puts "  #{name} #{vers}"
        end
      end
    end

  end

end

