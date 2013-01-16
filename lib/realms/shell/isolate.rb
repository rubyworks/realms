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

        op.banner = "Usage: realm isolate [PATH]"
        op.separator "Create an isolation template."

        op.on('--development', '-d', "include development dependencies.") do
          development = true
        end

        op.on('--gem', '-g', "Generate a template for use via RubyGems.") do
          format = :gem
        end

        op.on('--lib', '-l', "Generate a template in YAML format.") do
          format = :library
        end

        parse

        location = argv.first || Dir.pwd  # TODO: Utils.locate_root ?

        library = $LOAD_MANAGER.add(location)

        generate_isolation_template(location, development, format)
      end

    private

      #
      # Generate isolation template.
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
            { 'name'=>lib.name, 'version'=>lib.version.to_s }
          }.to_yaml
        when :library
          $LOAD_MANAGER.each do |name, lib|
            puts "library '%s', '= %s'" % [lib.name, lib.version]
          end
        else
          JSON.pretty_generate($LOAD_MANAGER.to_h)
        end
      end

    end
  end
end
