module Roll

  class Library

    # = Metadata
    #
    # This is essentially the same class as used by Reap
    # except stripped of all static attributes and opened
    # up as an "openstruct" instead.
    #
    class Metadata

      instance_methods.each{ |s| private s unless s.to_s =~ /^(__|instance_|object_|class)/ }

      METAFILE = 'meta{,data}{.yaml,.yml}'

      # Project's root directory.
      attr :rootdir

      # Metadata directory.
      attr :metadir

      # YAML based metadata file.
      attr :metafile

      # The metadata hash.
      attr :metadata

      # Version stamp.     
      #attr :version_stamp

      # New Metadata object.
      #
      def initialize(rootdir)
        @rootdir = rootdir
        metadata_reload
      end

      #
      #
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
      #
      def metadata?
        @metadir || @metafile
      end

      #
      #
      def method_missing(s, *a, &b)
        raise ArgumentError if block_given?
        case s = s.to_s
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

      #class << self
      #  alias_method :_new, new
      #  def new
      #    if defined?(::Reap)
      #      ::Reap::Metadata.new(location)
      #    else
      #      Metadata._new(location)
      #    end
      #  end
      #end

    end #class Metadata

  end #class Library

end #module Roll

