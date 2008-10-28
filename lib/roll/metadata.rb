module Roll

  class Library

    # Read metadata, if any exists. Metadata is purely extransous information.
    # The metadata will be a Reap::Metadata object if Reap is installed 
    # (providing more intelligent defaults), otherwise it  will be a  OpenStruct-like
    # object.
    #
    # TODO: Should we handle special ruby library differently?
    #
    def metadata
      @metadata ||= (
        if defined?(::Reap)
          ::Reap::Metadata.new(location)
        else
          Metadata.new(location)
        end
      )
    end

    # DEPRECATE
    alias_method :info, :metadata

    # Is metadata available?
    def metadata?
      metadata.metadata?
    end

    # If method is missing delegate to metadata, if any.
    def method_missing(s, *a, &b)
      if metadata
        metadata.send(s, *a, &b)
      else
        super
      end
    end

    # = Metadata
    #
    # This is essentially the same class as used by Reap
    # except stripped of all static attributes and opened
    # up as an "openstruct" instead.
    #
    class Metadata
      instance_methods.each{ |s| private s unless s.to_s =~ /^(__|instance_|object_|class)/ }

      METAFILE = 'meta{,data}{.yaml,.yml}'

      ### Project's root directory.
      attr :rootdir

      ### Metadata directory.
      attr :metadir

      ### YAML based metadata file.
      attr :metafile

      ### The metadata hash.
      attr :metadata

      ### Version stamp.
      #attr :version_stamp

      ### New Metadata object.
      def initialize(rootdir)
        @rootdir = rootdir
        metadata_reload
      end

      def metadata_reload
        #initialize_defaults

        metadir  = File.join(rootdir,'meta')
        metafile = Dir.glob(File.join(rootfolder,METAFILE), File::FNM_CASEFOLD).first

        if File.file?(metafile)
          @metafile = metafile
          data = YAML.load(File.new(file))
          data.each do |k,v|
            send("#{k}=", v)
          end
        end

        if File.directory?(metadir)
          @metadir = metadir
          Dir[File.join(metadir,'*')].each do |f|
            send("#{f.basename}=", f.read.strip) #if respond_to?("#{f.basename}=")
          end
        end
        #@version_stamp = VersionStamp.new(rootfolder)
      end

      #
      def metadata?
        @metadir || @metafile
      end

      #
      def method_missing(s, *a, &b)
        raise ArgumentError if block_given?
        case s.to_s
        when /=$/
          raise ArgumentError if a.size > 1
          @metadata[s.chomp('=')] = a[0]
        when /!$/
          super
        else
          raise ArgumentError if a.size > 0
          @metadata[s.chomp('?')]
        end
      end

    end

  end

end

