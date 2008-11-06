require 'roll/version'
require 'roll/install/svn'
require 'roll/install/git'

module Roll

  class Install

    STORE = '/opt/rolls/'

    # Project name
    attr_accessor :name

    # Repository URI
    attr_accessor :uri

    # Version
    attr_accessor :version

    # Version type is either :tag, :branch, :revision, or :version.
    attr_accessor :version_type

    # Supports rubyforge (default) and github.
    attr_accessor :host

    # Type of SCM used. Presently this is needed for first install.
    #attr_accessor :scm_type

    #
    def initialize(name, options={})
      raise "missing repository name" unless name
      @name = name.to_s
      @host = :rubyforge
      options.each do |k, v|
        __send__("#{k}=", v) if v && respond_to?("#{k}=")
      end
    end

    #
    def local
      @local ||= File.join(STORE, name)
    end

    #
    def origin
      @origin ||= File.join(local, '0')
    end

    #
    def store
      @store ||= STORE
    end

    #
    def scm_type
      @scm_type ||= (scm_check || :git)
    end

    # Return SCM type for project.
    def scm_check
      return :git if host == :github
      if version
        return :svn if File.directory?(File.join(local, version, '.svn'))
        return :git if File.directory?(File.join(local, version, '.git'))
      else
        return :svn if Dir[File.join(local, '*', '.svn')].first  # TODO: Maybe just origin.
        return :git if File.directory?(File.join(origin, '.git'))
      end
      # lets try to get it remotely
      scm_check_remote
    end

    #
    def scm_check_remote
      begin
        require 'open_uri'
        open('http://rubyforge/projects/#{name}/').read =~ /svn/im ? :svn : :git
      rescue
        nil
      end
    end

    #
    def uri
      case host
      when :guthub
        # TODO
      else
        case scm_type
        when :git
          'git://rubyforge.org/%s.git' % [name]
        when :svn
          'svn://rubyforge.org/var/svn/%s' % [name]
        end
      end
    end

    # Install project.
    def install
      delegate.install
    end

    # Uninstall project.
    def uninstall
      delegate.uninstall
    end

    # Update project.
    def update
      delegate.update
    end

    # Show a list of installable versions.
    def show
      vers = delegate.versions
      puts vers.join("\n") unless vers.empty?
    end

    #
    def delegate
      @delegate ||= (
        class_name = scm_type.to_s.capitalize
        Roll::Install::const_get(class_name).new(self, :uri=>uri)
      )
    end
  end

end

