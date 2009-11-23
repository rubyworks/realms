require 'open-uri'
require 'roll/version'
require 'roll/package/scm/svn'
require 'roll/package/scm/git'

module Roll    #:nodoc:
class  Package #:nodoc:
module Host

  # = Host Base class
  #
  # Base classes for all host classes.
  #
  class Base

    # Project name
    attr_accessor :project

    # Package name
    attr_accessor :package

    # DEPRECATE
    alias_method :name, :package

    # Repository URI
    attr_accessor :uri

    # Version
    attr_accessor :version

    # Store
    attr_accessor :store

    # Version type is either :tag, :branch, :revision, or :version.
    #attr_accessor :type

    #
    def initialize(project, package, options={})
      package = project unless package

      raise "missing project name" unless project
      raise "missing package name" unless package

      self.project = project.to_s
      self.package = package.to_s

      options.each do |k, v|
        __send__("#{k}=", v) if v && respond_to?("#{k}=")
      end

      #self.version = latest_version if !version

      raise "Could not determine version of #{package}." unless version
    end

    #
    def store
      @store ||= Package::DEFAULT_STORE
    end

    # DEPRECATE ?
    def local
      @local ||= File.join(store, name)
    end

    #
    def uri
      raise "where's the implementation, dude?"
    end

    #
    def scm
      raise "where's the implementation, dude?"
      #@scm ||= (
      #  class_name = scm_type.to_s.capitalize
      #  Roll::Install::const_get(class_name).new(self, :uri=>uri)
      #)
    end

    # Install project.
    def install
      scm.install
    end

    # Uninstall project.
    def uninstall
      scm.uninstall
    end

    # Update project.
    def update
      scm.update
    end

    # Show a list of installable versions.
    def show
      vers = scm.versions
      puts vers.join("\n") unless vers.empty?
    end

  end #class Base

end #module Host
end #module Package
end #module Roll

