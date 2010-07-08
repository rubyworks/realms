module Roll

  # Encapsulate functions to extract metadata from a POM-based project.
  #
  # TODO: require 'pom' ?
  class Metadata::POM

    # Does the given +path+ contain a POM based project?
    def self.match?(path)
      File.file?(File.join(path, 'PACKAGE')) or
      File.file?(File.join(path, 'PROFILE'))
    end

    #
    def initialize(location)
      @location = location
    end

    #
    def pom
      @pom ||= (
        require 'pom'
        POM::Metadata.new(location)
      )
    end

    #
    def location
      @location
    end

    #
    def name
      @name ||= pom.name
    end

    #
    def version
      @version ||= pom.version
    end

    #
    def loadpath
      @loadpath ||= pom.loadpath
    end

    #
    def namespace
      @namespace ||= pom.codename #namespace
    end

    #
    def nickname
      @namespace ||= pom.nickname #codename
    end

    #
    def date
      @date ||= pom.date
    end

    # TODO: more uniform access to pom data

    #
    def method_missing(s, *a)
      super unless a.empty? or block_given?
      pom.send(s)
    end

=begin
    # PACKAGE file path.
    def package_file
      @package_file ||= (
        paths = Dir.glob(File.join(location, "{,.}{package}{.yml,.yaml,}"), File::FNM_CASEFOLD)
        paths.select{ |f| File.file?(f) }.first
      )
    end

    # PROFILE file path.
    def profile_file
      @profile_file ||= (
        paths = Dir.glob(File.join(location, "{,.}profile{.yml,.yaml,}"), File::FNM_CASEFOLD)
        paths.select{ |f| File.file?(f) }.first
      )
    end

    # REQUIRE file path.
    def require_file
      @require_file ||= (
        pattern = File.join(location, "{,.}REQUIRE{.yml,.yaml,}")
        Dir.glob(pattern, File::FNM_CASEFOLD).first
      )
    end

    # Load metadata from PACKAGE file.
    def load_package
      if package_file
        data = YAML.load(File.new(package_file))
        data = data.inject({}){|h,(k,v)| h[k.to_s] = v; h}
        self.name     = data['name']
        self.version  = data['vers'] || data['version']
        self.loadpath = data['path'] || data['loadpath']
        self.nickname = data['nick'] || data['nickname']
        self.codename = data['code'] || data['namespace']
        true
      else
        false
      end
    end

    #
    def load_profile
      if profile_file
        YAML.load(File.new(profile_file))
      else
        {}
      end
    end

    # TODO: Improve.
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
=end

  end

end

