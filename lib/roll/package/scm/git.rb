require 'roll/package/scm/base'

module Roll     #:nodoc:
class  Package  #:nodoc:
module Scm      #:nodoc:

  # = Git
  #
  # This currently works by checking out the master repository
  # and then doing a local checkout of the desired version (tag).
  #
  # TODO: No doubt this probably can be implemented better, ie.
  # with more knowledge of Git's capabilities. The goal for now
  # though is just to get a working system.
  #
  class Git < Base

    # Install the project.
    def install
      check_version

      if File.exist?(destination)
        update
      else
        puts "Installing #{name}..."
        clone # checkout master
        system "git clone -l #{origin} #{destination}"
        if $PRETEND
          puts   "cd #{destination}"
          system "git checkout #{map[version]}"
        else
          Dir.chdir(destination) do
            system "git checkout #{map[version]}"
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

    #
    def versions
      @versions ||= map.keys
    end

    # Returns a list of tags.
    def tags
      @tags ||= (
        t = `git ls-remote -t #{uri}`
        t = t.split("\n")
        t = t.map do |line|
          rev, name = *line.split(/\s+/)
          name.sub('refs/tags/', '')
        end
        t = t.reject{ |x| x =~ /\{\}$/ }
        #t.delete('HEAD')
        #t.delete('refs/heads/master')
        t
      )
    end

    # Returns a list of branches.
    def branches
      @branches ||= (
        h = `git ls-remote -h #{uri}`
        h = h.split("\n")
        h = h.map do |line|
           rev, name = *line.split(/\s+/)
           name
        end
        h.delete('HEAD')
        h.delete('refs/heads/master')
        h
      )
    end

  private

    def clone
      if File.exist?(origin)
        Dir.chdir(origin) do
          system "git pull -t origin"  ##{uri}"
        end
      else
        system "git clone #{uri} #{origin}"
      end
    end

    #
    def check_version
      if not versions.include?(version)
        raise "#{version} does not exist."
      end
    end

    # Map version names to tag url.
    def map
      @map ||= (
        m = {}
        tags.each do |tag|
          m[clean_name(tag)] = tag #"#{uri}/#{tag}"
        end
        m
      )
    end

    # Clean tag name. This removes leading markers
    # like 'v' and 'REL_'.
    def clean_name(name)
      name.
      sub(/^REL_/, '').
      sub(/^v(?!:[0-9])/, '')
    end

  end#class Git

end#module Scm
end#module Package
end#module Roll

