# Currently only support SVN. Git will be next.

#$DEBUG = true

require 'yaml'
require 'roll/version'


module Roll

  class InstallManager

    attr :packages

    def initialize
      @packages = {}
    end

    # TODO: Make configurable.

    def site
      "svn://rubyforge.org/var/svn/%s"
    end

    # TODO: Make configurable

    def store
      "/opt/rubyrolls/"
    end

    #

    def install(name, constraint=nil)
      name = name.to_s
      uri  = site % [name]

      puts "Scanning for #{name} packages..."
      scan(uri)

      if pkg = match(name, constraint)
        uri = pkg[:uri]
        dir = pkg[:dir]
        if $DEBUG
          p "chdir #{store}"
          p "svn co #{File.join(uri,dir)} #{File.join(name, dir)}"
        else
          Dir.chdir(store) do
            system "svn co #{File.join(uri,dir)} #{File.join(name, dir)}"
          end
        end
      else
        puts "no matching package -- #{name}, #{constraint}"
      end
    end

    def scan(uri)
      files = `svn list -R #{uri}`
      files = files.split(/\n/)
      rolls = files.select do |file|
        file =~ /rollrc$/i
      end
      rolls.each do |file|
        dir, file = File.split(file)
        if (meta = File.basename(dir)) =~ /meta/i
          dir  = File.dirname(dir)
          file = File.join(meta, file)
        end
        add_package(uri, dir, file)
      end
    end

    #

    def add_package(uri, dir, file)
      data = `svn cat #{File.join(uri, dir,file)}`
      data = parse_roll(data.strip)
      data[:uri]    = uri
      data[:dir]    = dir
      data[:rollrc] = file
      name = data[:name].to_s.downcase
      packages[name] ||= []
      packages[name] << data
    end

    # This parses the ROLLRC file. It's is very simplistic for the sake of speed.
    # Can it be faster?
    #--
    def parse_roll(data)
      info, *libpath = *data.split(/\n\s*/)
      name, version, status, release, main = info.split(/\s+/)
      name, status, main = name, status, main
      version = VersionNumber.new(version)
      release = Time.mktime(*release.sub('(','').chomp(')').split('-'))
      return {
        :name    => name,
        :version => version,
        :status  => status,
        :release => release,
        :main    => main,
        :libpath => libpath
      }
    end

    # Returns the highest matching version in packages.

    def match(name, constraint)
      if constraint
        matches = packages[name].select do |name, pkg|
          pkg[:version] #...
        end
      else
        matches = packages[name]
      end
      matches.max{ |a,b| a[:version] <=> b[:version] }
    end

  end

end



if __FILE__ == $0

  imgr = Roll::InstallManager.new
  imgr.install('facets')

end
