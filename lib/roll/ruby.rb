module Roll

  #
  class RubyLibrary < Library

    # New library.
    def initialize #(location, name=nil, options={})
      @location = '' # TODO where?
      @name     = 'ruby'
      @options  = {} #?
    end

    #
    def version
      RUBY_VERSION
    end

    # TODO: 1.9+ need to remove rugbygems ?
    def loadpath
      @loadpath ||= $LOAD_PATH - ['.']
      #$LOAD_PATH - ['.']
      #[Config::CONFIG['rubylibdir'], Config::CONFIG['archdir']].compact
    end

    # Release date. TODO
    def released
      Time.now
    end

    # Ruby requires nothing.
    def requires
      []
    end

    # Ruby needs to ignore a few 3rd party libraries. They will
    # be picked up by the final fallback to Ruby's original require
    # if all else fails.
    def find(file, suffix=true)
      return nil if /^rdoc/ =~ file
      super(file, suffix)
    end

    # Location of executable. This is alwasy bin/. This is a fixed
    # convention, unlike lib/ which needs to be more flexable.
    def bindir
      File.join(location, 'bin')
    end

    # Is there a <tt>bin/</tt> location?
    def bindir?
      File.exist?(bindir)
    end

    # Location of library system configuration files.
    # This is alwasy the <tt>etc/</tt> directory.
    def confdir
      File.join(location, 'etc')
    end

    # Is there a <tt>etc/</tt> location?
    def confdir?
      File.exist?(confdir)
    end

    # Location of library shared data directory.
    # This is always the <tt>data/</tt> directory.
    def datadir
      File.join(location, 'data')
    end

    # Is there a <tt>data/</tt> location?
    def datadir?
      File.exist?(datadir)
    end

    #
    def require_absolute(file)
      path = loadpath_sorted.find{ |lp| file.start_with?(lp) }.chomp('/') + '/'
      return false if $".include?(file.sub(path, ''))  # ruby 1.8 does not use absolutes
      super(file)
    end

    #
    def loadpath_sorted
      loadpath.sort{ |a,b| b.size <=> a.size }
    end

  end

end

