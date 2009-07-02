module Roll

  class Library

    # = Metadata
    #
    # This is essentially the same class as used by Reap
    # except stripped of all static attributes and opened
    # up as an "openstruct" instead.
    #
    # TODO: Use Pom::Metadata ?
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
        @rootdir  = rootdir
        @metadata = {}
        metadata_reload
      end

      #
      #
      def metadata_reload
        #initialize_defaults

        metadir = Dir.glob(File.join(rootdir,'{meta,.meta}')).first
        if metadir && File.directory?(metadir)
          @metadir = metadir
        end

        metafile = Dir.glob(File.join(rootdir,METAFILE), File::FNM_CASEFOLD).first
        if metafile && File.file?(metafile)
          @metafile = metafile
          data = YAML.load(File.new(file))
          data.each do |k,v|
            self[k] = v
          end
        end

        #if metadir && File.directory?(metadir)
        #  @metadir = metadir
        #  Dir[File.join(metadir,'*')].each do |f|
        #    send("#{File.basename(f)}=", File.read(f).strip) #if respond_to?("#{f.basename}=")
        #  end
        #end

        #@version_stamp = VersionStamp.new(rootfolder)
      end

      #
      #def metadir
      #  @metadir ||= Dir.glob(File.join(rootdir,'{meta,.meta}/')).first
      #end

      #
      #
      def metadata?
        metadir || metafile
      end

      #
      #
      def method_missing(s, *a, &b)
        raise ArgumentError if block_given?
        case s = s.to_s
        when /=$/
          raise ArgumentError if a.size > 1
          s = s.chomp('=')
          @metadata[s] = a[0]
        when /!$/
          super
        else
          raise ArgumentError if a.size > 0
          s = s.chomp('?')
          self[s]
        end
      end

      #
      def []=(key, val)
        key = key.to_s
        @metadata[key] = val
      end

      #
      def [](key)
        key = key.to_s
        if @metadata.key?(key)
          @metadata[key]
        else
          @metadata[key] = read_metadata(key)
        end
      end

      #
      def read_metadata(name)
        return nil unless metadir
        file = File.join(metadir, name)
        if File.file?(file)
          File.read(file).strip
        else
          nil
        end
      end

      def name=(x)
        @metadata['package'] = x
      end

      def name
        self['name'] || self['package']
      end

      def released=(x)
        @metadata['date'] = x
      end

      def released
        self['released'] || self['date']
      end

      def loadpath
        @metadata['loadpath'] ||= (
           self.loadpath = read_metadata('loadpath')
           @metadata['loadpath']
        )
      end

      alias_method :load_path, :loadpath

      # Wish there was a way to know this without
      # using a configuration file.
      def loadpath=(paths)
        paths ||= 'lib'
        @metadata['loadpath'] = paths.split(/\n/).map{ |l| l.strip }.select{ |l| l =~ /\w/ }
      end

      alias_method :load_path=, :loadpath=

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

