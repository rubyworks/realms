require 'roll/install/base'

module Roll

  class Install

    # Currently this only supports Rubyforge repositories.
    class Svn < Base

      def initialize_defaults
        @uri = "svn://rubyforge.org/var/svn/%s" % [name]
      end

      #
      def install
        puts "Installing #{name} packages..."

        url = scan

        if version
          dir = File.join(store, name, version)
        else
          dir = origin
        end

        if $PRETEND
          puts "svn co #{url} #{dir}"
        else
          system "svn co #{url} #{dir}"
        end

        return dir
      end

      # MAYBE: Use the VERSION file to determine which
      #        folders are usable as "packages"?
      def scan
p uri
        case version_type
        when :tag
          tags = `svn list #{uri}/tags/`
          tags = tags.split("\n")
          if tags.emtpy?
            url = uri + "/#{version}"
          else
            # MAYBE: verfity if exists
            url = uri + "/tags/#{version}"
          end
        when :branch
          branches = `svn list #{uri}/branches/`
          branches = branches.split("\n")
          if branches.emtpy?
            url = uri + "/#{version}"
          else
            # MAYBE: verfity if exists
            url = uri + "/branches/#{version}"
          end
        when :version
          # How to handle ?
        when :revision
          url = uri + " -r #{version}"
        else
          # install latest (assumes 'trunk')
          url = uri + "/trunk"
        end
p url
        return url
      end

      # Update
      def update
        if version
          dir = File.join(store, name, version)
        else
          dir = origin
        end
        Dir.chdir(dir) do
          system "svn update"
        end
      end

      # Returns list of available versions (ie. tags and branches).
      def versions
        tags = `svn list #{uri}/tags/`
        tags = tags.split("\n")

        branches = `svn list #{uri}/branches/`
        branches = branches.split("\n")

        versions = tags + branches

        if versions.empty?
          versions = `svn list #{uri}/`
          versions = versions.split("\n")
        end

        versions = versions.collect{ |v| v.chomp('/') }

        return versions
      end

      #
      #def show
      #  puts versions.join("\n")
      #end

=begin
        cmd = "svn list -R #{uri}"
        puts cmd
        files = `#{cmd}`
        files = files.split(/\n/)
puts files.join("\n")
        rolls = files.select do |file|
          file =~ /VERSION(\.txt)?$/i
        end
        rolls.each do |file|
          dir, file = File.split(file)
          #if (meta = File.basename(dir)) =~ /meta/i
          #  dir  = File.dirname(dir)
          #  file = File.join(meta, file)
          #end
          add_package(uri, dir, file)
        end
      end

      #
      def add_package(uri, dir, file)
        data = `svn cat #{File.join(uri, dir, file)}`
        data = parse_version_file(data.strip)
        data[:uri]  = uri
        data[:dir]  = dir
        data[:file] = file
        name = data[:name].to_s.downcase
        packages[name] ||= []
        packages[name] << data
      end

      # This parses the VERSION file. It's is very simplistic for
      # the sake of speed.
      def parse_version_file(data)
        info, *libpath = *data.split(/\n\s*/)
        name, version, status, release, default = info.split(/\s+/)
        #name, status, main = name, status, main
        version = VersionNumber.new(version)
        release = Time.mktime(*release.sub('(','').chomp(')').split('-'))
        return {
          :name    => name,
          :version => version,
          :status  => status,
          :release => release,
          :default => default,
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
=end

    end#class Svn

  end#module Install

end#module Roll

