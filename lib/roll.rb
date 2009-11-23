module Roll
  VERSION = "0.1"  #:till: VERSION = "<%= version %>"

  require 'roll/kernel'
  #Roll::Library.setup

  #def self.current
  #end

  # Get environment.

  def self.env(name=nil)
    if name
      env = Environment.new(name)
    else
      env = Environment.new
    end
    env
  end

  # Synchronize an environment by +name+. If no
  # +name+ is given, synchronize all environments.

  def self.sync(name=nil)
    if name
      list = [name]
    else
      list = Environment.list
    end
    list.each do |name|
      env = Environment.new(name)
      env.sync
      env.save
    end
  end

  # Add path to current environment.

  def self.in(path, depth=3)
    env = Environment.new

    locals = env.locals
    locals.append(path, depth)

    env.sync
    env.save

    return path, locals.file
  end

  # Remove path from current ledger.

  def self.out(path)
    env = Environment.new

    locals = env.locals
    locals.delete(path)

    env.sync
    env.save

    return path, locals.file
  end

end

