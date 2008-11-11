module Roll

  module Install

    STORE = '/opt/rolls/'

    # = Scm
    #
    # Base class for all scm installers.
    # These are tightly coupled to the
    # Install class which delegates to them.
    class Scm

      # Host
      attr :host

      # Repository URI
      attr :uri

      #
      def initialize(installer, uri, options={})
        @host = host
        @uri  = uri
        #options[:uri] if options[:uri]
      end

      # Project name
      def name
        host.name
      end

      # Version
      def version
        host.version
      end

      # Version type is either :tag, :branch, :revision, or :version.
      def version_type
        host.version_type
      end

      # TODO: Make configurable ?
      def store
        host.store
      end

      # Origin is the install location of the current
      # repository (eg. the "trunk" or "master" versions).
      def origin
        host.origin
      end

      #
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

