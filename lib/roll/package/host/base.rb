require 'open-uri'
require 'roll/version'
require 'roll/package/scm/svn'
require 'roll/package/scm/git'

module Roll #:nodoc:
module Package #:nodoc:
module Host

  # = Host Base class
  #
  # Base classes for all host classes.
  #
  class Base

    DEFAULT_STORE = '/opt/rolls/'

    # Project name
    attr_accessor :name

    # Repository URI
    attr_accessor :uri

    # Version
    attr_accessor :version

    # Version type is either :tag, :branch, :revision, or :version.
    #attr_accessor :type

    #
    def initialize(name, options={})
      raise "missing repository name" unless name
      @name = name.to_s
      options.each do |k, v|
        __send__("#{k}=", v) if v && respond_to?("#{k}=")
      end
    end

    #
    def store
      @store ||= DEFAULT_STORE
    end

    #
    def local
      @local ||= File.join(store, name)
    end

    #
    def origin
      @origin ||= File.join(local, '0')
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

