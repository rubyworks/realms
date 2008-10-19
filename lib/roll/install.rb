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

    # Type of SCM used. Presently this is needed for first install.
    attr_accessor :scm_type

    #
    def initialize(name, options={})
      raise "missing repository name" unless name
      @name = name.to_s
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
    #--
    # TODO: Is there a way to figure out the scm type remotely?
    #++
    def scm_check
      if version
        return :svn if File.directory?(File.join(local, version, '.svn'))
        return :git if File.directory?(File.join(local, version, '.git'))
      else
        return :svn if Dir[File.join(local, '*', '.svn')].first  # TODO: Maybe just origin.
        return :git if File.directory?(File.join(origin, '.git'))
      end
      return nil
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
        Roll::Install::const_get(class_name).new(self)
      )
    end
  end

end

