class Library

  #
  class Requirements

    include Enumerable

    #
    def initialize(location)
      @location     = location
      @dependencies = nil
    end

    # Location of project.
    def location
      @location
    end

    # Returns an array of `[name, constraint]`.
    def dependencies
      @dependencies || load_require_file
    end

    # TODO: split runtime from all others
    def runtime
      dependencies
    end

    #
    def exist?
      File.exist?(File.join(location, 'REQUIRE'))
    end

    #
    def load_require_file
      return []

      #require 'yaml'
      dependencies = []
      file = File.join(location, 'REQUIRE')
      if File.exist?(file)
        begin
          data = YAML.load(File.new(file))
          list = []
          data.each do |type, reqs|
            list.concat(reqs)
          end
          list.each do |dep|
            name, *vers = dep.split(/\s+/)
            vers = vers.join('')
            vers = nil if vers.empty?
            dependencies << [name, vers]
          end
        rescue
          $stderr.puts "roll: failed to load requirements -- #{file}"
          dependencies = []
        end
      end
      @dependencies = dependencies
    end

    # Returns a list of Library and/or [name, vers] entries.
    # A Libray entry means the library was loaded, whereas the
    # name/vers array means it failed. (TODO: Best way to do this?)
    #
    # TODO: don't do stdout here
    def verify(verbose=false)
      libs, fail = [], []
      dependencies.each do |name, vers|
        lib = Library[name, vers]
        if lib
          libs << lib
          $stdout.puts "  [LOAD] #{name} #{vers}" if verbose
          unless libs.include?(lib) or fail.include?(luib)
            lib.requirements.verify(verbose)
          end
        else
          fail << [name, vers]
          $stdout.puts "  [FAIL] #{name} #{vers}" if verbose
        end
      end
      return libs, fail
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

