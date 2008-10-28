class Library

  # VersionError is raised when a requested version cannot be found.
  class VersionError < ::RangeError  # :nodoc:
  end

  # VersionConflict is raised when selecting another version
  # of a library when a previous version has already been selected.
  class VersionConflict < ::LoadError  # :nodoc:
  end

  # Roll configuration.
  #sysdir  = Config::CONFIG['sysconfdir']
  #sysfile = File.join(sysdir, 'roll.yaml')
  #if File.exist?(sysfile)
  #  ROLL_CONFIG = YAML.load(File.new(sysfile))
  #else
  #  ROLL_CONFIG = { 'path' => [] }
  #end

  # FIXME: when using sudo roll. maybe put back in etc/roll/ ?
  #        and use .etc/roll/ for per-user rolls.
  #ROLL_PATH = ENV['ROLL_PATH']

  # Central locations for roll-ready libraries.
  #rolldir = 'ruby_site'
  #sitedir = Config::CONFIG['sitedir']
  #version = Config::CONFIG['ruby_version']
  #default = File.join(File.dirname(sitedir), rolldir, version)

  #LOAD_SITE = [default] #+ ENV['ROLL_PATH'].to_s.split(/[:;]/)  # TODO add '.' ?
  #LOAD_SITE.concat(ROLL_PATH.to_s.split(/[:;]/))  # TODO add '.' ?
end

