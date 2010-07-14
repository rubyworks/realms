require 'roll/library'

module Roll

  # RubyLibrary is a specialized subclass of Library specifically designed
  # to sever Ruby's standard library. It is used to speed up load times for
  # for library files that are standard Ruby scripts and should never be
  # overriden by any 3rd party libraries. Good examples are 'ostruct' and
  # 'optparse'.
  #
  # This class is in the proccess of being refined to exclude certian 3rd
  # party redistributions, such RDoc and Soap4r.
  class RubyLibrary < Library

    # New library.
    def initialize #(location, name=nil, options={})
      @location = Config::CONFIG['rubylibdir']
      @name     = 'ruby'
      @options  = {} #?
    end

    #
    def version
      RUBY_VERSION
    end

    #
    ARCHPATH = Config::CONFIG['archdir'].sub(Config::CONFIG['rubylibdir']+'/', '')

    # TODO: 1.9+ need to remove rugbygems ?
    def loadpath
      @loadpath ||= [ '', ARCHPATH ]
      #$LOAD_PATH - ['.']
      #$LOAD_PATH - ['.']
      #[], ].compact
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

    # Require library +file+ given as a LibFile instance.
    #
    # file - Instance of LibFile.
    #
    # Returns Boolean success of requiring the file.
    def require_absolute(file)
      return false if $".include?(file.localname)  # ruby 1.8 does not use absolutes
      success = super(file)
      $" << file.localname # ruby 1.8 does not use absolutes
      $".uniq!
      success
    end

    # Load library +file+ given as a LibFile instance.
    #
    # file - Instance of LibFile.
    #
    # Returns Boolean success of loading the file.
    def load_absolute(file, wrap=nil)
      success = super(file, wrap)
      $" << file.localname # ruby 1.8 does not use absolutes
      $".uniq!
      success
    end

    # The loadpath sorted by largest path first.
    def loadpath_sorted
      loadpath.sort{ |a,b| b.size <=> a.size }
    end

    # Construct a LibFile match.
    def libfile(lpath, file, ext)
      LibFile.new(self, lpath, file, ext) 
    end
  end

end

