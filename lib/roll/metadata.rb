require 'yaml'

module Roll

  #= Library Metadata
  #--
  # TODO: Use POM? If available?
  #
  # TODO: Improve loading and parsing of metadata.
  # We want this to be as fast and as lazy as possible.
  #--
  class Metadata

    # New metadata object.
    def initialize(location, name=nil, options={})
      @location = location
      @name     = name
      @version  = options[:version]
      @loadpath = options[:loadpath]
      #load_metadata
    end

    # Location of library.
    attr :location

    # Release date.
    attr_accessor :date

    # Alias for release date.
    alias_method :released, :date

    # In code name, e.g. "ActiveRecord"
    attr_accessor :codename

    # Local load paths.
    def loadpath
      @loadpath ||= (
        load_metadata
        @loadpath || ['lib']
      )
    end

    #
    def loadpath=(path)
      case path
      when nil
        path = ['lib']
      when String
        path = path.strip.split(/[,;:\ \n\t]/).map{|s| s.strip}
      end
      @loadpath = path
    end

    # Name of library.
    def name
      @name || (
        if @loaded
          nil
        else
          load_metadata
          @name
        end
      )
    end

    # Set name.
    def name=(string)
      @name = string if string
    end

    # Version number.
    #
    # Technically, a library should not appear in a ledger list
    # if it lacks a VERSION file. However, just in case this
    # occurs (say by a hand edited environment) we fallback
    # to a version of '0.0.0'.
    def version
      @version ||= (
        load_metadata
        @version || Version.new('0.0.0')
      )
    end

    # Set version, converts string into Version number class.
    def version=(string)
      @version = Version.new(string) if string
    end

    # TODO: Improve. Is this even needed?
    def requires
      @requires ||= (
        req = []
        if file = require_file
          data = YAML.load(File.new(file))
          data.each do |name, list|
            req.concat(list || [])
          end
        end
        req
      )
    end

    #
    def require_file
      @require_file ||= (
        pattern = File.join(location, "{REQUIRE,.require}{,.yml,.yaml}")
        Dir.glob(pattern, File::FNM_CASEFOLD).first
      )
    end

    # TODO: Deprecate active, if you don't want it exclude from environment.
    # Is active, i.e. not omitted.
    #def active  ; true ; end
    # Is active, i.e. not omitted.
    #def active? ; true ; end

  private

    # Package file path.
    def package_file
      @package_file ||= (
        paths = Dir.glob(File.join(location, "{,.}{package}{.yml,.yaml,}"), File::FNM_CASEFOLD)
        paths.select{ |f| File.file?(f) }.first
      )
    end

    # Version file path.
    def version_file
      @version_file ||= (
        paths = Dir.glob(File.join(location, "{VERSION}{,.txt,.yml,.yaml}"), File::FNM_CASEFOLD)
        paths.select{ |f| File.file?(f) }.first
      )
    end

    #
    def load_metadata
      @loaded = true
      load_package || load_fallback
    end

    #
    def load_package
      if package_file
        data = YAML.load(File.new(package_file))
        data = data.inject({}){|h,(k,v)| h[k.to_s] = v; h}
        self.name     = data['name']
        self.version  = data['vers'] || data['version']
        self.loadpath = data['path'] || data['loadpath']
        self.codename = data['code'] || data['codename']
        true
      else
        false
      end
    end

    # TODO: Instead of supporting gemspecs as is, create a tool
    # that will add a .package file to each one.

    #
    #def load_gemspec
    #  return false unless File.basename(File.dirname(location)) == 'gems'
    #  specfile = File.join(location, '..', '..', 'specifications', File.basename(location) + '.gemspec')
    #  if File.exist?(specfile)
    #    fakegem = FakeGem.load(specfile)
    #    self.name     = fakegem.name
    #    self.version  = fakegem.version
    #    self.loadpath = fakegem.require_paths
    #    true
    #  else
    #    false
    #  end 
    #end

    # THINK: Is this reliable enough?
    def load_fallback
      load_location
      load_version unless @version
      if not @version
        self.version = '0.0.0'
      end
      @name
    end

    #
    def load_location
      fname = File.basename(location)
      if /\-\d/ =~ fname
        i = fname.rindex('-')
        name, vers = fname[0...i], fname[i+1..-1]
        self.name    = name
        self.version = vers
      else
        self.name = fname
      end
    end

    # Try to determine name from lib/*.rb file.
    # Ideally this would work, but there are too many projects that do not
    # follow best practices, so currently THIS IS NOT USED.
    def load_loadpath
      #libs = loadpath.map{ |lp| Dir.glob(File.join(lp,'*.rb')) }.flatten
      libs = Dir.glob(File.join(location, 'lib', '*.rb'))
      if !libs.empty?
        self.name = File.basename(libs.first).chomp('.rb')
        true
      else
        false
      end
    end

    # Load VERSION file, if it exists.
    def load_version
      if version_file
        ext = File.extname(version_file)
        if ext == '.yml' or ext == '.yaml'
          data = YAML.load(File.new(version_file))
          parse_version_hash(data)
        else
          text = File.read(version_file).strip
          if text[0..3] == '---' or text.index('major:')
            data = YAML.load(text)
            parse_version_hash(data)
          else
            parse_version_string(text)
          end
        end
        true if @version
      else
        false
      end
    end

    # Parse hash-based VERSION file.
    def parse_version_hash(data)
      data = data.inject({}){ |h,(k,v)| h[k.to_sym] = v; h }
      self.name = data[:name] if data[:name]
      self.date = data[:date] if data[:date]
      # jeweler
      if data[:major]
        self.version = data.values_at(:major, :minor, :patch, :build).compact.join('.')
      else
        vers = data[:vers] || data[:version]
        self.version = (Array === vers ? vers.join('.') : vers)
      end
      self.codename = data.values_at(:code, :codename).compact.first
    end

    # Parse string-based VERSION file.
    def parse_version_string(text)
      text = text.strip
      # name
      if md = /^(\w+)(\-\d|\ )/.match(text)
        self.name = md[1]
      end
      # version
      if md = /(\d+\.)+(\w+\.)?(\d+)/.match(text)
        self.version = md[0]
      end
      # date
      # TODO: convert to date/time
      if md = /\d\d\d\d-\d\d-\d\d/.match(text)
        self.date = md[0]
      end
    end

=begin
    ## Get library active state.
    #def active
    #  return @cache[:active] if @cache.key?(:active)
    #  @cache[:active] = (
    #    case read(:active).to_s.downcase
    #    when 'false', 'no'
    #      false
    #    else
    #      true
    #    end
    #  )
    #end

    #
    def method_missing(name, *args)
      if @cache.key?(name)
        @cache[name]
      else
        @cache[name] = read(name)
      end
    end
=end

=begin
    # Retrieve entry from meta directory.
    def meta(name)
      file = Dir[File.join(location, "{meta,.meta}", name.to_s)].first
      if file
        text = File.read(file)
        if text =~ /^---/
          require_yaml
          YAML.load(text)
        else
          text.strip
        end
      else
        nil
      end
    end
=end

    # Ecapsulate the fake parsing of a gemspec.
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

  end

end

