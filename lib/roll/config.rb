require 'rbconfig'

module ::Config

  # Return the path to the data directory associated with the given
  # library name.
  #--
  #Normally this is just
  # "#{Config::CONFIG['datadir']}/#{name}", but may be
  # modified by packages like RubyGems and Rolls to handle
  # versioned data directories.
  #++

  def self.datadir(name, versionless=false)
    if lib = Roll::Library.instance(name)
      lib.datadir(versionless)
    else
      File.join(CONFIG['datadir'], name)
    end
  end

  # Return the path to the configuration directory.

  def self.confdir(name)
    if lib = Roll::Library.instance(name)
      lib.confdir
    else
      File.join(CONFIG['confdir'], name)
    end
  end
end

