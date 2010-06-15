require 'roll/config'
require 'roll/library'
require 'roll/kernel'  # require last

module Roll
  VERSION = "1.2.0"  # TODO: make verison reference dynamic

  # Get environment.
  def self.env(name=nil)
    if name
      env = Environment.new(name)
    else
      env = Environment.new
    end
    env
  end

  # Change current environment.
  def self.use(name)
    Environment.save(name)
  end

  # Return Array of environment names.
  def self.list
    Environment.list
  end

  #
  def self.index(name=nil)
    #if name
    #  env = Environment.new(name)
    #else
    #  env = Environment.new
    #end
    env(name).index.to_s
  end

  # Synchronize an environment by +name+. If a +name+
  # is not given the current environment is synchronized.
  def self.sync(name=nil)
    env = env(name)
    env.sync
    env.save
  end

  # Add path to current environment.
  def self.in(path, depth=3)
    env = Environment.new

    lookup = env.lookup
    lookup.append(path, depth)
    lookup.save

    env.sync
    env.save

    return path, lookup.file
  end

  # Remove path from current environment.
  def self.out(path)
    env = Environment.new

    lookup = env.lookup
    lookup.delete(path)
    lookup.save

    env.sync
    env.save

    return path, lookup.file
  end

  # Go thru each roll lib and collect bin paths.
  def self.path
    binpaths = []
    Library.list.each do |name|
      lib = Library[name]
      if lib.bindir?
        binpaths << lib.bindir
      end
    end
    binpaths
  end

  # Verify dependencies are in current environment.
  #--
  # TODO: Instead of Dir.pwd, lookup project root.
  #++
  def self.verify(name=nil)
    if name
      Library.open(name).verify
    else
      Library.new(Dir.pwd).verify
    end
  end

  # VersionError is raised when a requested version cannot be found.
  class VersionError < ::RangeError  # :nodoc:
  end

  # VersionConflict is raised when selecting another version
  # of a library when a previous version has already been selected.
  class VersionConflict < ::LoadError  # :nodoc:
  end

end

