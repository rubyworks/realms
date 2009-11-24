require 'roll/kernel'

module Roll
  VERSION = "2.0"  #:till: VERSION = "<%= version %>"

  # Get environment.

  def self.env(name=nil)
    if name
      env = Environment.new(name)
    else
      env = Environment.new
    end
    env
  end

  # Synchronize an environment by +name+. If a +name+
  # is not given the current environment is synchronized.

  def self.sync(name=nil)
    env = name ? Environment.new(name) : Environment.new
    env.sync
    env.save
  end

  # Add path to current environment.

  def self.in(path, depth=3)
    env = Environment.new

    locals = env.locals
    locals.append(path, depth)
    locals.save

    env.sync
    env.save

    return path, locals.file
  end

  # Remove path from current environment.

  def self.out(path)
    env = Environment.new

    locals = env.locals
    locals.delete(path)

    env.sync
    env.save

    return path, locals.file
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

end

