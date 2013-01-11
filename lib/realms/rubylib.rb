require 'rbconfig'
require 'library'

# RubyLibrary is a specialized subclass of Library specifically designed
# to serve Ruby's standard library locations. It is used to speed up load
# times for for library files that are standard Ruby scripts and should never
# be overriden by any 3rd party libraries. Good examples are 'ostruct' and
# 'optparse'.
#
# This class is in the proccess of being refined to exclude certian 3rd
# party redistributions, such RDoc and Soap4r.
#
class RubyLibrary < Library

  include ::RbConfig

  #
  def self.singleton
    @r ||= new
  end

  #
  # Setup Ruby library.
  #
  def initialize(*) #(location, metadata={})
    paths = CONFIG.values_at(
      'rubylibdir',
      'archdir',
      'sitedir',
      'sitelibdir',
      'sitearchdir',
      'vendordir',
      'vendorlibdir',
      'vendorarchdir'
    )

    location = find_base_path(paths)
    loadpath = paths.map{ |d| d.sub(location + '/','') }

    @location = location
    @loadpath = loadpath
    @name     = 'ruby'
    @metadata = {}  # TODO: can we fillout Ruby's metadata some ?
  end

  #
  # Then name of RubyLibrary is `ruby`.
  #
  def name
    'ruby'
  end

  #
  # Ruby version is RUBY_VERSION.
  #
  def version
    RUBY_VERSION
  end

  # TODO: Remove rugbygems from $LOAD_PATH and use that?

  # TODO: Sometimes people add paths directly to $LOAD_PATH,
  #   should these be accessible via `ruby/`?

  #
  # Load path is essentially $LOAD_PATH, less gem paths.
  #
  def loadpath
    #$LOAD_PATH - ['.']
    @loadpath
  end

  alias load_path loadpath

  #
  # Release date.
  #
  # @todo This currently just returns current date/time.
  #   Is there a way to get Ruby's own release date?
  #
  def date
    Time.now
  end

  #
  alias released date

  #
  # Ruby requires nothing.
  #
  def requirements
    []
  end

  #
  # Ruby needs to ignore a few 3rd party libraries. They will
  # be picked up by the final fallback to Ruby's original require
  # if all else fails.
  #
  def find(file, suffix=true)
    return nil if /^rdoc/ =~ file
    super(file, suffix)
  end

  #
  # Location of executables, which for Ruby is `RbConfig::CONFIG['bindir']`.
  #
  def bindir
    ::RbConfig::CONFIG['bindir']
  end

  #
  # Is there a `bin/` location?
  #
  def bindir?
    File.exist?(bindir)
  end

  #
  # Location of library system configuration files.
  # For Ruby this is `RbConfig::CONFIG['sysconfdir']`.
  #
  def confdir
    ::RbConfig::CONFIG['sysconfdir']
  end

  #
  # Is there a "`etc`" location?
  #
  def confdir?
    File.exist?(confdir)
  end

  #
  # Location of library shared data directory. For Ruby this is
  # `RbConfig::CONFIG['datadir']`.
  #
  def datadir
    ::RbConfig::CONFIG['datadir']
  end

  #
  # Is there a `data/` location?
  #
  def datadir?
    File.exist?(datadir)
  end

  #
  # Require library +file+ given as a Script instance.
  #
  # @param [String] feature
  #   Instance of Feature.
  #
  # @return [Boolean] Success of requiring the feature.
  #
  def require_absolute(feature)
    return false if $".include?(feature.localname)  # ruby 1.8 does not use absolutes
    success = super(feature)
    $" << feature.localname # ruby 1.8 does not use absolutes TODO: move up?
    $".uniq!
    success
  end

  #
  # Load library +file+ given as a Script instance.
  #
  # @param [String] feature
  #   Instance of Feature.
  #
  # @return [Boolean] Success of loading the feature.
  #
  def load_absolute(feature, wrap=nil)
    success = super(feature, wrap)
    $" << feature.localname # ruby 1.8 does not use absolutes TODO: move up?
    $".uniq!
    success
  end

  #
  # The loadpath sorted by largest path first.
  #
  def loadpath_sorted
    loadpath.sort{ |a,b| b.size <=> a.size }
  end

  #
  # Construct a Script match.
  #
  def libfile(lpath, file, ext=nil)
    Library::Feature.new(self, lpath, file, ext) 
  end

private

  # Given an array of path strings, find the longest common prefix path.
  def find_base_path(paths)
    return paths.first if paths.length <= 1
    arr = paths.sort
    f = arr.first.split('/')
    l = arr.last.split('/')
    i = 0
    i += 1 while f[i] == l[i] && i <= f.length
    f.slice(0, i).join('/')
  end

end

