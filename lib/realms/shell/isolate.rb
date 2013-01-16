module Realms
  class Library
    module Shell
      register :isolate

      #
      # Create an isolation index.
      #
      def isolate
        development = false
        format = nil

        op.banner = "Usage: realm isolate"
        op.separator "Create an isolation template."

        op.on('--development', '-d', "include development dependencies.") do
          development = true
        end

        op.on('--gem', '-g', "Generate a template for use via RubyGems.") do
          format = :gem
        end

        op.on('--yaml', '-y', "Generate a template in YAML format.") do
          format = :yaml
        end

        parse

        location = argv.first || Dir.pwd  # TODO: find root ?

        library = $LOAD_MANAGER.add(location)

        generate_isolation_template(location, development, format)
      end

    private

      #
      #
      #
      def generate_isolation_template(library, development, format=nil)
        $LOAD_MANAGER.isolate_library(library, development)
        case format
        when :gem
          $LOAD_MANAGER.each do |name, lib|
            puts "gem '%s', '= %s'" % [lib.name, lib.version]
          end
        when :gemfile
          $LOAD_MANAGER.each do |name, lib|
            puts "gem '%s', '= %s'" % [lib.name, lib.version]
          end
        when :yaml
          puts $LOAD_MANAGER.map{ |name, lib|
            { 'name'=>lib.name, 'version'=>lib.version.to_s } #, 'groups'=>lib.groups, 'development'=>lib.development? }
          }.to_yaml
        else
          $LOAD_MANAGER.each do |name, lib|
            puts "library '%s', '= %s'" % [lib.name, lib.version]
          end
        end
      end


=begin
      # TODO: Move most of this code into library somewhere.
      def generate_isolate_index(location, development=nil)
        require 'fileutils'

        #if opts[:all]
        #  list = Roll.environments
        #else
        #  list = [Roll.environment.name]
        #end

        library = Library.new(location)
        ledger  = $LOAD_MANAGER.dup

        results = ledger.activate_requirements(library, development)

        fails, libs = results.partition{ |r| Array === r }

        if fails.empty?
          out = ''

          max_name = results.map{ |lib| lib.name.size }.max
          max_path = results.map{ |lib| lib.location.size }.max

          results.each do |lib|
            out << "%-#{max_name}s  %-#{-max_path}s  %s\n" % [lib.name, lib.location, lib.loadpath.join(' ')]
          end

#          dir = Roll.config.local_environment_directory

          #FileUtils.mkdir_p(dir)

          #file = File.join(dir, 'local')

          #File.open(file, 'w'){ |f| f << out }

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
=end

    end
  end
end
