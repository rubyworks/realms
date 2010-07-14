module Roll

  #
  class Requirements

    include Enumerable

    #
    def initialize(location)
      @location = location
    end

    # Location of project.
    def location
      @location
    end

    # Returns an array of `[name, constraint]`.
    def dependencies
      @dependencies || load_require_file
    end

    #
    def load_require_file
      dependencies = []
      file = File.join(location, 'REQUIRE')
      if File.exist?(file)
        list = []
        data = YAML.load(File.new(file))
        data.each do |type, reqs|
          list.concat(reqs)
        end
        list.each do |dep|
          name, *vers = dep.split(/\s+/)
          vers = vers.join('')
          vers = nil if vers.empty?
          dependencies << [name, vers]
        end
      end
      @dependencies = dependencies
    end

    # Returns a list of Library and/or [name, vers] entries.
    # A Libray entry means the library was loaded, whereas the
    # name/vers array menas it failed. (TODO: Best way to do this?)
    def verify(verbose=false)
      libs, fail = [], []
      dependencies.each do |name, vers|
        lib = Library[name, vers]
        if lib
          libs << lib
          $stderr.puts "  [LOAD] #{name} #{vers}" if verbose
        else
          libs << [name, vers]
          $stderr.puts "  [FAIL] #{name} #{vers}" if verbose
        end
      end
      return libs
    end

    #
    def each #:yield:
      dependencies.each{|x| yield(x) }
    end

    #
    def size
      dependencies.size
    end

    #
    def empty?
      dependencies.empty?
    end
  end

end

