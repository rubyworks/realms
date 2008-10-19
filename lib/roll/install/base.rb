module Roll

  class Install

    STORE = '/opt/rolls/'

    # Base class for all scm installers.
    # These are tightly coupled to the 
    # Install class which delegates to them.
    #
    class Base

      attr :installer

      # Repository URI
      attr_accessor :uri

      #
      def initialize(installer)
        @installer = installer

        initialize_defaults
      end

      # Project name
      def name
        installer.name
      end

      # Version
      def version
        installer.version
      end

      # Version type is either :tag, :branch, :revision, or :version.
      def version_type
        installer.version_type
      end

      # TODO: Make configurable ?
      def store
        installer.store
      end

      # Origin is the install location of the current
      # repository (eg. the "trunk" or "master" versions).
      def origin
        installer.origin
      end

      def system(cmd)
        if $PRETEND
          puts cmd
        else
          super(cmd)
        end
      end

    end#class Base

  end#module Install

end#module Roll

