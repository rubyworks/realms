require 'roll/package/host/base'

module Roll     #:nodoc:
class  Package  #:nodoc:
module Host     #:nodoc:

  # = Rubyforge
  #
  class Rubyforge < Base

    #
    def uri
      case scm_type
      when :git
        'git://rubyforge.org/%s.git' % [package]
      when :svn
        'svn://rubyforge.org/var/svn/%s/%s' % [project, package]
      end
    end

    #
    def scm
      @scm ||= (
        case scm_type
        when :git
          Scm::Git.new(project, package, :version=>version, :uri=>uri, :store=>store)
        when :svn
          Scm::Svn.new(project, package, :version=>version, :uri=>uri, :store=>store)
        else
          raise "can't determine scm type"
        end
      )
    end

    # What is the SCM type (:git or :svn). Fallback is :git.
    def scm_type
      @scm_type ||= scm_check
    end

    # Return SCM type for project.
    def scm_check
      if version
        return :svn if File.directory?(File.join(local, version, '.svn'))
        return :git if File.directory?(File.join(local, version, '.git'))
      #else
      #  return :svn if Dir[File.join(local, '*', '.svn')].first  # TODO: Maybe just origin.
      #  return :git if File.directory?(File.join(origin, '.git'))
      end
      # lets try to get it remotely
      scm_check_remote
    end

    # Remotely check the SCM type.
    def scm_check_remote
      begin
        #proj = name.split(/[\\\/]/).first
        open("http://rubyforge.org/projects/#{project}/").read =~ /SVN/im ? :svn : :git
      #rescue
        #nil
      end
    end

    # Remotely get the latest version of a package.
    # TODO: This is harder than it looks!
    #def latest_version
    #  raise "verison is required"
      #proj = name.split(/[\\\/]/).first
      #page = open("http://rubyforge.org/projects/#{proj}/").read
      #regx = Regexp.escape("#{name}</strong></td><td>") + "\s*(*.?)\s*" + Regexp.escape("</td>")
      #if md = regx.match(page)
      #  md[1]
      #else
      #  nil
      #end
    #end

  end #class Rubyforge

end #module Host
end #module Package
end #module Roll

