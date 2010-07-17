require 'rbconfig'

module ::Config

  # TODO: use "XDG-lite" rather than XDG ?

  # User's home directory.
  HOME = File.expand_path('~') # ENV['HOME']

  # Location of user's personal config directory.
  CONFIG_HOME = File.expand_path(ENV['XDG_CONFIG_HOME'] || File.join(HOME, '.config'))

  # Location of user's personal temporary directory.
  CACHE_HOME  = File.expand_path(ENV['XDG_CACHE_HOME'] || File.join(HOME, '.cache'))

  # List of user shared system config directories.
  CONFIG_DIRS = (
    dirs = ENV['XDG_CONFIG_DIRS'].to_s.split(/[:;]/)
    if dirs.empty?
      dirs = [File.join(Config::CONFIG['sysconfdir'], 'xdg')]
    end
    dirs.collect{ |d| File.expand_path(d) }
  )

  # Patterns used to identiy a Windows platform.
  WIN_PATTERNS = [
    /bccwin/i,
    /cygwin/i,
    /djgpp/i,
    /mingw/i,
    /mswin/i,
    /wince/i,
  ]

  WINDOWS_PLATFORM = !!WIN_PATTERNS.find{ |r| RUBY_PLATFORM =~ r }

  # Is this a windows platform? This method compares the entires
  # in +WIN_PATTERNS+ against +RUBY_PLATFORM+.
  def self.windows_platform?
    WINDOWS_PLATFORM
  end

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

  # Lookup configuration file.
  def self.find_config(*glob)
    flag = 0
    flag = (flag | glob.pop) while Fixnum === glob.last
    find = []
    [CONFIG_HOME, *CONFIG_DIRS].each do |dir|
      path = File.join(dir, *glob)
      if block_given?
        find.concat(Dir.glob(path, flag).select(&block))
      else
        find.concat(Dir.glob(path, flag))
      end
    end
    find
  end

end
