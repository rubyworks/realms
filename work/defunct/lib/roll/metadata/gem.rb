module Roll

  # Encapsulate functions to extract metadata for a installed Gem project,
  # or a project with a .gemspec file.
  class Metadata::Gem

    #
    def self.match?(path)
      return true if Dir[File.join(path, '*.gemspec')].first

      pkgname = File.basename(path)
      gemsdir = File.dirname(path)
      specdir = File.join(File.dirname(gemsdir), 'specifications')
      return true if Dir[File.join(specdir, "#{pkgname}.gemspec")].first

      return false
    end

    #
    def initialize(location)
      @location = location
      if !local_gemspec_file
        parse_location
      end
    end

    #
    def parse_location
      pkgname = File.basename(location)

      if md = /^(.*?)\-(\d+)$/.match(pkgname)
        @name     = md[1]
        @version  = md[2]
      end

      file = File.join(location, '.require_paths')
      if File.exist?(file)
        text = File.read(file)
        @loadpath = text.strip.split(/\s*\n/)
        #@loadpath = text.split(/[,;:\ \n\t]/).map{|s| s.strip}
      end
    end

    #
    def location
      @location
    end

    #
    def name
      @name ||= gem.name
    end

    #
    def version
      @version ||= gem.version.to_s
    end

    #
    def loadpath
      @loadpath ||= gem.require_paths
    end

    #
    #def namespace
    #  @namespace ||= gem.namespace
    #end

    #
    #def nickname
    #  @namespace ||= gem.codename
    #end

    #
    def date
      @date ||= gem.date
    end

    # TODO: more uniform access to gemspec data

    #
    def method_missing(s, *a)
      super unless a.empty? or block_given?
      gem.send(s)
    end

    #
    def gem
      @_gem ||= (
        require 'rubygems'
        ::Gem::Specification.load(gemspec_file)
      )
    end

    #
    def gemspec_file
      local_gemspec_file || system_gemspec_file
    end

    #
    def local_gemspec_file
      @_local__gemspec_file ||= Dir[File.join(location, '*.gemspec')].first
    end

    def system_gemspec_file
      @_system_gemspec_file ||= (
        pkgname = File.basename(location)
        gemsdir = File.dirname(location)
        specdir = File.join(File.dirname(gemsdir), 'specifications')
        Dir[File.join(specdir, "#{pkgname}.gemspec")].first
      )
    end


=begin
    # TODO: Instead of supporting gemspecs as is, create a tool
    # that will add a .package file to each one.
    #
    def load_gemspec
      return false unless File.basename(File.dirname(location)) == 'gems'
      specfile = File.join(location, '..', '..', 'specifications', File.basename(location) + '.gemspec')
      if File.exist?(specfile)
        fakegem = FakeGem.load(specfile)
        self.name     = fakegem.name
        self.version  = fakegem.version
        self.loadpath = fakegem.require_paths
        true
      else
        false
      end 
    end

    # Ecapsulates the fake parsing of a gemspec.
    #
    module FakeGem
      module Gem #:nodoc:
        class Specification #:nodoc:
          attr :fake_options
          def initialize(&block)
            @fake_options = {}
            yield(self)
          end
          def method_missing(sym, *args)
            name = sym.to_s
            case name
            when /=$/
              @fake_options[name.chomp('=')] = args.first
            else
              @fake_options[name]
            end
          end
        end
        class Requirement
          def initialize(*a)
          end
        end
      end
      #
      def self.load(file)
        text = File.read(file)
        fake_spec = eval(text, binding)
        fake_spec
      end
    end
=end

  end

end
