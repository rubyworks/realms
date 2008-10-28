require 'roll/config'
require 'roll/version'
require 'roll/metadata'

#require 'roll/loadpath'
#require 'roll/sign'

#require 'roll/library/constants'
#require 'roll/library/metaclass'
#require 'roll/library/instance'
#require 'roll/library/kernel'

module Roll

  # = Library
  #
  class Library

    # Path to library.
    attr_reader :location

    # Name of library.
    attr_reader :name

    # Version of library. This is a Version object.
    attr_reader :version

    # Release date.
    attr_reader :date

    # Alias for date.
    alias_method :released, :date

    # Status of project.
    attr_reader :status

    # Libraries load paths.
    attr_reader :load_path

    # Library dependencies. These are libraries that will be searched
    # if a file is not found in the main libpath.
    #attr_reader :requires

    # New Library.
    def initialize(metadata)
      location = metadata[:location]
      name     = metadata[:name]
      version  = metadata[:version]
      date     = metadata[:date]
      status   = metadata[:status]
      loadpath = metadata[:loadpath]

      raise "no name -- #{location}"    unless name
      raise "no version -- #{location}" unless version

      @location = location
      @name     = name

      if version
        @version = (Version===version) ? version : Version.new(version)
      end

      if date
        @date = (Time===date) ? date : Time.mktime(*date.scan(/[0-9]+/))
      end

      @status  = status

      @load_path = loadpath || ['lib']
    end

    # Inspection.
    def inspect
      if version
        "#<Library #{name}/#{version}>"
      else
        "#<Library #{name}>"
      end
    end

    # Compare by version.
    def <=>(other)
      version <=> other.version
    end

    #
    def activate
      load_path.each do |lp|
        $LOAD_PATH.unshift(File.join(location, lp))
      end
    end

    # Location of binaries. This is alwasy bin/. This is a fixed
    # convention, unlike lib/ which needs to be more flexable.
    def bin
      File.join(location, 'bin')
    end

    def bin?
      File.directory?(bindir)
    end

    # Returns the path to the data directory, ie. {location}/data.
    # Note that this does not look in the system's data share (/usr/share/{name}).
    def data #(versionless=false)
      File.join(location, 'data')
    end

    def data?
      File.directory?(datadir)
    end

    # Returns the path to the configuration directory, ie. {location}/etc.
    # Note that this does not look in the system's configuration directory (/etc/{name}).
    #
    # TODO: This in particluar probably should look in the
    #       systems config directory-- maybe an overlay effect?
    def etc
      File.join(location, 'etc')
    end

    def etc?
      File.directory?(etcdir)
    end

    # Traditional names.
    alias_method :bindir , :bin
    alias_method :datadir, :data
    alias_method :confdir, :etc
  end

end

