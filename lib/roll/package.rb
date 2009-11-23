require 'roll/package/host/rubyforge'
require 'roll/package/host/github'

module Roll

  # = Package
  #
  # The name is a misonomer, since Roll's does not deal
  # in packages, but rather SCM repositories. However,
  # until a better alternative comes forth, it suffices
  # to convey the intention of this part of Rolls. Ie.
  # It serves in place of a traditional package manager.
  #
  class Package

    STORE = '/opt/rolls/' # TODO: Adjust STORE

    attr :project

    attr :package

    attr :version

    attr :store

    attr :uri

    #
    def host_type
      @host_type
    end

    #
    def initialize(project, package, ioc)
      package = project if !package
      @project   = project
      @package   = package
      @version   = ioc[:version]
      @store     = ioc[:store]
      @host_type = ioc[:host]
      @uri       = ioc[:uri]
    end

    #
    def store
      @store ||= STORE
    end

    # TODO: Could use environment variable or config to set default host.
    def host
      @host ||= (
        case host_type
        when :rubyforge
          Host::Rubyforge.new(project, package, host_options)
        when :github
          Host::Github.new(project, package, host_options)
        else
          puts "Unspecified host. Assuming RubyForge."
          Host::Rubyforge.new(project, package, host_options)
        end
      )
    end

    #
    def host_options
      opts = {}
      opts[:version] = version if version
      opts[:store]   = store   if store
      opts[:uri]     = uri     if uri
      opts
    end

    # Scm based on local snapshot.
    def scm
      @scm ||= (
        case scm_type
        when :git
          Scm::Git.new(project, package, scm_options)
        when :svn
          Scm::Svn.new(project, package, scm_options)
        else
          raise "can't determine scm type"
        end
      )
    end

    #
    def scm_options
      opts = {}
      opts[:version] = version if version
      opts[:store]   = store   if store
      opts[:version] = uri     if uri
      opts
    end

    #
    def scm_type
      return :svn if File.directory?(File.join(store, package, version, '.svn'))
      return :git if File.directory?(File.join(store, package, version, '.git'))
      return :svn if File.directory?(File.join(store, package, '0', '.svn'))
      return :git if File.directory?(File.join(store, package, '0', '.git'))
      return nil
    end

    # Install project.
    #
    def install
      dir = host.install
      insert(dir) if not $PRETEND
    end

    # Update project.
    #
    def update
      scm.update
    end

    # Update project.
    #
    def uninstall
      scm.uninstall
    end

    # insert installation into ledger
    #
    # TODO: Add option to add to universal ledger?
    def insert(dir)
      dir = File.expand_path(dir)
      ledger = Library.user_ledger #Library.system_ledger
      ledger << dir
      ledger.save
      puts "#{dir}" 
      puts "  '-> #{Library.user_ledger_file}"
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

  end #class Package

end #module Roll

