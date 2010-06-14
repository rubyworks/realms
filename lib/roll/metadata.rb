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
    def initialize(location, name=nil)
      @location = location
      @name     = name
      @version  = nil
      #load_metadata
    end

    # Location of library.
    attr :location

    # Release date.
    attr_accessor :date

    # Alias for release date.
    alias_method :released, :date

    # Version code name, e.g. "Hardy Haron"
    attr_accessor :codename

    # Local load paths.
    def loadpath
      @loadpath || load_loadpath
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
      @name || load_name
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
      @version || load_version
    end

    # Set version, converts string into Version number class.
    def version=(string)
      @version = Version.new(string) if string
    end

    # TODO: Improve. Is this even needed?
    def requires
      @requires ||= (
        if file = require_file
          data = YAML.load(File.new(file))
          data['runtime'] + data['production']
        else
          []
        end
      )
    end

    #
    def require_file
      @require_file ||= (
        pattern = File.join(location, "{REQUIRE,.require}{,.yml,.yaml}")
        File.glob(pattern, File::FNM_CASEFOLD).first
      )
    end

    # TODO: Deprecate active, if you don't want it exclude from environment.
    # Is active, i.e. not omitted.
    #def active  ; true ; end
    # Is active, i.e. not omitted.
    #def active? ; true ; end

  private

    #
    def load_metadata
      load_loadpath
      load_version
      load_name
    end

    #
    def load_loadpath
      self.loadpath = meta('loadpath') || ['lib']
      @loadpath
    end

    #
    def load_name
      # first try version b/c it might have the name
      version; return @name if @name # version file had the name
      if val = meta('name')
        self.name = val
      else
        #libs = loadpath.map{ |lp| Dir.glob(File.join(lp,'*.rb')) }.flatten
        libs = Dir.glob(File.join(location, 'lib', '*.rb'))
        if libs.empty?
          self.name = File.basename(location).sub(/\-\d.*?$/, '')
        else
          self.name = File.basename(libs.first).chomp('.rb')
        end
      end
      @name
    end

    #
    def load_version
      if version_file
        ext = File.extname(version_file)
        if ext == '.yml' or ext == '.yaml'
          data = YAML.load(File.new(version_file))
          parse_version_hash(data)
        else
          text = File.read(version_file).strip
          if text[0..3] == '---'
            data = YAML.load(text)
            parse_version_hash(data)
          else
            parse_version_string(text)
          end
        end
      else
        fname = File.basename(File.dirname(location))
        if md = /\-(\d.*?)$/.match(fname)
          self.version = md[1]
        end
      end
      if not @version
        self.version = meta('version') || '0.0.0'
      end
      @version
    end

    # Version file path.
    def version_file
      @version_file ||= Dir.glob(File.join(location, "{VERSION}{,.txt,.yml,.yaml}"), File::FNM_CASEFOLD).first
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
      else
        fname = File.basename(File.dirname(location))
        if md = /^(\w+)(\-\d|$)/.match(fname)
          self.name = md[1]
        else
          raise "roll: name needed for #{location}"
        end
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

  private

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

  end

end
