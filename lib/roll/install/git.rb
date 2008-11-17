require 'roll/install/scm'

module Roll

  module Install

    # = Git
    #
    # For Git there's no distinction between branches, tags
    # and revisions --they are just different labels on the
    # same thing.
    #
    # TODO: No doubt this could be implemented better, eg. with more
    # knowledge of Git's capabilities. The goal for now though is
    # just to get a working system.

    class Git < Scm

      # Install the project.
      def install
        check_version

        if File.exist?(destination)
          update
        else
          puts "Installing #{name}..."
          clone
          if $PRETEND
            system "git clone -l #{origin} #{destination}"
            puts "cd #{dest}"
            system "git checkout #{version}"
            #git checkout --track -b {branch} origin/{branch}
          else
            Dir.chdir(destination) do
              system "git checkout #{version}"
              #git checkout --track -b {branch} origin/{branch}
            end
          end
        end

        return destination
      end

      # TODO: Maybe this should be "purge", and uninstall just removes it from the ledger.
      def uninstall
        unless File.directory?(destination)
          raise "#{version} is not installed"
        end
        FileUtils.rm_r(destination)
      end

      # Update
      def update
        Dir.chdir(destination) do
          system "git rebase #{version}"
        end
      end

      # Returns a list of existing versions/branches.
      def versions
        @versions ||= (
          vs = []
          `git ls-remote #{uri}`.split("\n").each do |line|
             rev, name = *line.split(/\s+/)
             vs << name
          end
          vs.delete('HEAD')
          vs.delete('refs/heads/master')
          return vs
        )
      end

      def destination
        File.join(store, name, version)
      end

    private

      # TODO: use natcmp for max
      def version
        @version ||= versions.max
      end

      def clone
        system "git clone #{uri} #{origin}"
      end

      #
      def check_version
        if @version && !versions.include?(@version)
          raise "#{@version} does not exist"
        end
      end

    end#class Git

  end#module Install

end#module Roll

