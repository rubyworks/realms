require 'roll/xdg'
require 'roll/library'
require 'roll/kernel'

# = Roll
#
module Roll

  # VersionError is raised when a requested version cannot be found.
  class VersionError < ::RangeError  # :nodoc:
  end

  # VersionConflict is raised when selecting another version
  # of a library when a previous version has already been selected.
  class VersionConflict < ::LoadError  # :nodoc:
  end

  ###########
  extend self
  ###########

  def ledger
    @ledger
  end

  def locations
    @locations
  end

  # = New Roll Manager
  #
  def setup
    @ledger    = {}
    @locations = []

    ledger_files.each do |file|
      locs = File.read(file).split(/\s*\n/)
      locations.concat(locs)
    end

    load_projects(*locations)
  end

  # TODO: config or share is the proper directory?
  def ledger_files
    @ledger_files ||= XDG.config_select('roll/ledger.list')
  end

  #
  def user_ledger_file
    @user_ledger_file ||= File.join(XDG.home_config, 'roll/ledger.list')
  end

  # Return a list of library names.
  def list
    ledger.keys
  end

  # TODO: load_path
  def load_projects(*locations)
    locations.each do |location|
      begin
        metadata = load_version(location)
        metadata[:location] = location
        metadata[:loadpath] = load_loadpath(location)

        lib = Library.new(metadata)

        name = lib.name.downcase

        @ledger[name] ||= []
        @ledger[name] << lib

        @locations << location
      rescue => e
        raise e if ENV['ROLL_DEBUG'] or $DEBUG
        warn "scan error, library omitted -- #{location}" if ENV['ROLL_WARN'] or $VERBOSE
      end
    end
  end

  # Load and parse version stamp file.
  def load_version(location)
    patt = File.join(location,'VERSION')
    file = Dir.glob(patt, File::FNM_CASEFOLD).first
    if file
      parse_version_stamp(File.read(file))
    else
      {}
    end
  end

  # Wish there was a way to do this without using a
  # configuration file.
  def load_loadpath(location)
    file = File.join(location, 'meta', 'loadpath')
    if File.file?(file)
      paths = File.read(file).gsub(/\n\s*\n/m,"")
      paths = paths.split(/\s*\n/)
    else
      paths = ['lib']
    end
  end

  # Parse version stamp into it's various parts.
  def parse_version_stamp(text)
    #info, *libpath = *data.split(/\s*\n\s*/)
    name, version, status, date = *text.split(/\s+/)
    version = Version.new(version)
    date    = Time.mktime(*date.scan(/[0-9]+/))
    #default = default || "../#{name}"
    return {:name => name, :version => version, :status => status, :date => date}
  end

  # Libraries are Singleton pattern.
  def instance(name, constraint=nil)
    name = name.to_s

    #raise "no library -- #{name}" unless ledger.include?( name )
    return nil unless ledger.include?(name)

    library = ledger[name]

    if Library===library
      if constraint
        raise VersionConflict, "previously selected version -- #{ledger[name].version}"
      else
        library
      end
    else # library is an array of versions
      if constraint
        compare = VersionNumber.constrant_lambda(constraint)
        library_version = library.select(&compare).max
      else
        library_version = library.max
      end
      unless library_version
        raise VersionError, "no library version -- #{name} #{constraint}"
      end
      library_version.activate
      ledger[name] = library_version
    end
  end

  # A shortcut for #instance.
  alias_method :[], :instance

  # Same as #instance but will raise and error if the library is not found.
  def open(name, constraint=nil, &yld)
    lib = instance(name, constraint)
    unless lib
      raise LoadError, "no library -- #{name}"
    end
    yield(lib) if yld
    lib
  end

end


