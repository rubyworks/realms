module Roll

  # = Installer
  #
  class Installer
    attr :name
    attr :host_type
    attr :options

    #
    def initialize(name, host_type, options)
      @name = name
      @host_type = host_type
      @options = options
    end

    # Install project.
    #
    def install
      case host_type
      when :rubyforge
        host = Roll::Rubyforge.new(name, options)
      when :github
        host = Roll::Github.new(name, options)
      else
        raise "unknown host"
      end

      dir = host.install

      # insert installation into ledger
      if not $PRETEND
        Dir.chdir(dir){ insert }
      end
    end

    # Compile extensions. Valid types of extensions are extconf.rb
    # files, configure scripts and rakefiles or mkrf_conf files.
    #
    def compile
      return if @spec.extensions.empty?
      say "Building native extensions.  This could take a while..."
      start_dir = Dir.pwd
      dest_path = File.join @gem_dir, @spec.require_paths.first
      ran_rake = false # only run rake once

      @spec.extensions.each do |extension|
        break if ran_rake
        results = []

        compiler = Compiler.new

        #builder = case extension
        #          when /extconf/ then
        #            Compile::ExtConf
        #          when /configure/ then
        #            Compile::Configure
        #          when /rakefile/i, /mkrf_conf/i then
        #            ran_rake = true
        #            Compile::Rake
        #          else
        #            results = ["No builder for extension '#{extension}'"]
        #            nil
        #          end

        begin
          Dir.chdir(File.join(@gem_dir, File.dirname(extension)))

          results = compiler.build(extension, @gem_dir, dest_path, results)

          say results.join("\n") if Gem.configuration.really_verbose

        rescue => ex
          results = results.join "\n"

          File.open('gem_make.out', 'wb') { |f| f.puts results }

          message = <<-EOF
ERROR: Failed to build gem native extension.

#{results}

Gem files will remain installed in #{@gem_dir} for inspection.
Results logged to #{File.join(Dir.pwd, 'gem_make.out')}
          EOF

          raise ExtensionBuildError, message
        ensure
          Dir.chdir start_dir
        end
      end

    end

  end

end

