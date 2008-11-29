require 'roll/scm/base'

module Roll

  module Scm

    # = Svn
    #
    # The Svn class assumes a layout of branches/tags/trunk,
    # but if this is not present will fallback to treating
    # all entries in the repository's root as tags.
    #
    class Svn < Base

      # Install project.
      def install
        if File.exist?(destination)
          update
        else
          puts "Installing #{name}..."
          system "svn co #{url} #{destination}"
        end
        return destination
      end

      # Update project.
      def update
        Dir.chdir(destination) do
          system "svn update"
        end
      end

      #
      def url
        if versions.include?(version)
          @map[version]
        else
          raise "version not found"
        end
      end

      # Returns list of available versions.
      # These are the tags with the tag names
      # cleaned-up.
      def versions
        @versions ||= map.keys
      end

      # Returns list of available tags.
      def tags
        @tags ||= (
          if subdirectory?
            t = `svn list #{uri}/tags/`
            t = t.split("\n")
            t = t.map{ |v| v.chomp('/') }
          else
            t = list
          end
          t
        )
      end

      # Returns list of available branches.
      def branches
        @branches ||= (
          if subdirectory?
            b = `svn list #{uri}/branches/`
            b = b.split("\n")
            b = b.map{ |v| v.chomp('/') }
          else
            b = []
          end
          b
        )
      end

    private

      #
      def list
        @list ||= (
          l = `svn list #{uri}/`
          l = l.split("\n")
          l = l.map{ |v| v.chomp('/') }
          l
        )
      end

      # Is the subversion repository using the standard
      # tags/branches/trunk layout?
      def subdirectory?
        list.include?('tags') or list.include?('branches')
      end

      # Map version names to tag url.
      def map
        @map ||= (
          m = {}
          tags.each do |tag|
            if subdirectory?
              m[clean_name(tag)] = "#{uri}/tags/#{tag}"
            else
              m[clean_name(tag)] = "#{uri}/#{tag}"
            end
          end
          m
        )
      end

      # Clean tag name. This removes leading markers
      # like 'v' and 'REL_'.
      def clean_name(tagname)
        tagname.sub(/^#{name}/, '').
                sub(/^release/, '').
                sub(/^REL/, '').
                sub(/^v(?!:[0-9])/, '').
                sub(/^[_-]/, '')
      end

    end#class Svn

  end#module Install

end#module Roll






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

