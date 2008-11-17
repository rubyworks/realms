module Roll

  # = Installer
  #
  class Installer
    attr :name
    attr :host_type
    attr :options

    #
    def initialize(name, host_type, options)
      @name      = name
      @host_type = host_type
      @options   = options
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
      insert(dir) if not $PRETEND
    end

    # insert installation into ledger
    def insert(dir)
      dir = File.expand_path(dir)
      ledger = Roll.system_ledger
      ledger << dir
      ledger.save
      puts "#{dir}" 
      puts "  '-> #{Roll.system_ledger_file}"
    end

    # TODO: Where to get extensions?
    def extensions
      []
    end

    # TODO: Where to get loadd_paths?
    def load_paths
      ['lib']
    end

    # Compile extensions. Valid types of extensions are extconf.rb
    # files, configure scripts and rakefiles or mkrf_conf files.
    #
    def compile
      return if extensions.empty?
      puts "Compiling native extensions.  This could take a while..."
      start_dir = Dir.pwd
      dest_path = load_paths.first  # FIXME: Where is load_paths?

      compiler = Compiler.new

      # Ensure there is only one entry for each extension;
      # this should also ensure Rakefile only runs once.
      extensions.uniq!

      extensions.each do |extension|
        results = []

        begin
          Dir.chdir(File.dirname(extension))

          results = compiler.build(extension, dest_path, results)

          puts results.join("\n") if $DEBUG  #verbose?

        rescue => err
          results = results.join("\n")

          File.open('roll_make.out', 'wb'){ |f| f.puts results }

          message = "ERROR: Failed to compile native extension." +
                    "\n\n#{results}\n\n" +
                    "Results logged to #{File.join(Dir.pwd, 'roll_make.out')}"

          raise Error, message
        ensure
          Dir.chdir start_dir
        end
      end
    end

  end #class Installer

end #module Roll

