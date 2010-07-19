require 'rbconfig'

module ::RbConfig

  # Return the path to the data directory associated with the given
  # library name.
  #
  # Normally this is just:
  #
  #   "#{Config::CONFIG['datadir']}/#{name}"
  #
  # But it may be modified by packages like RubyGems and Rolls to handle
  # versioned data directories.
  def self.datadir(name, versionless=false)
    if lib = Roll::Library.instance(name)
      lib.datadir(versionless)
    elsif defined?(super)
      super(name)
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

  # Patterns used to identiy a Windows platform.
  WIN_PATTERNS = [
    /bccwin/i,
    /cygwin/i,
    /djgpp/i,
    /mingw/i,
    /mswin/i,
    /wince/i,
  ]

  #WINDOWS_PLATFORM = !!WIN_PATTERNS.find{ |r| RUBY_PLATFORM =~ r }

  # Is this a windows platform? This method compares the entires
  # in +WIN_PATTERNS+ against +RUBY_PLATFORM+.
  def self.windows_platform?
    case RUBY_PLATFORM
    when *WIN_PATTERNS
      true
    else
      false
    end
  end

end

