require 'roll/install/base'

module Roll

  module Install

    # = Git
    #
    # For Git there's no distinction between branches, tags
    # and revisions --they are just different labels on the
    # same thing.
    #
    class Git < Base

      # Install the project.
      def install
        if version
          unless versions.include?(version)
            raise "#{version} does not exist"
          end
        end

        puts "Installing #{name}..."

        clone

        if version
          dest = File.join(store, name, version)
          system "git clone -l #{local_origin} #{dest}"

          if $PRETEND
            puts "cd #{dest}"
            system "git checkout #{version}"
            #git checkout --track -b {branch} origin/{branch}
          else
            Dir.chdir(dest) do
              system "git checkout #{version}"
              #git checkout --track -b {branch} origin/{branch}
            end
          end
        else
          dest = local_origin
        end

        return dest
      end

      #
      def uninstall
        if version
          dest = File.join(store, name, version)
          unless File.directory?(dest)
            raise "#{dest} does not exist"
          end
          FileUtils.rm_r(dest)
        else

        end
      end

      # Update
      def update
        if version
          dest = File.join(store, name, version)
          Dir.chdir(dest) do
            system "git pull"
          end
        else
          Dir.chdir(local_origin) do
            system "git pull"
          end
        end
      end

      # Returns a list of existing versions/branches.
      def versions
        vs = []
        `git ls-remote #{uri}`.split("\n").each do |line|
           rev, name = *line.split(/\s+/)
           vs << name
        end
        vs.delete('HEAD')
        vs.delete('refs/heads/master')
        return vs
      end

      # Show versions.
      #def show
      #  vers = versions
      #  if vers.empty?
      #  else
      #    puts versions.join("\n")
      #  end
      #end

    private

      #def local_origin
      #  @local_origin ||= File.join(store, name, '0')
      #end

      def clone
        system "git clone #{uri} #{origin}"
      end

    end#class Git

  end#module Install

end#module Roll

