require 'roll/install/host'

module Roll

  module Install

    # = Rubyforge
    #
    class Rubyforge < Host

      #
      def uri
        case scm_type
        when :git
          'git://rubyforge.org/%s.git' % [name]
        when :svn
          'svn://rubyforge.org/var/svn/%s' % [name]
        end
      end

      #
      def scm
        @scm ||= (
          case scm_type
          when :git
            Git.new(self, :uri=>uri)
          when :svn
            Svn.new(self, :uri=>uri)
          end
        )
      end

      # What is the SCM type (:git or :svn). Fallback is :git.
      def scm_type
        @scm_type ||= (scm_check || :git)
      end

      # Return SCM type for project.
      def scm_check
        if version
          return :svn if File.directory?(File.join(local, version, '.svn'))
          return :git if File.directory?(File.join(local, version, '.git'))
        else
          return :svn if Dir[File.join(local, '*', '.svn')].first  # TODO: Maybe just origin.
          return :git if File.directory?(File.join(origin, '.git'))
        end
        # lets try to get it remotely
        scm_check_remote
      end

      # Remotely check the SCM type.
      def scm_check_remote
        begin
          require 'open_uri'
          open('http://rubyforge/projects/#{name}/').read =~ /svn/im ? :svn : :git
        rescue
          nil
        end
      end

    end #class Rubyforge

  end #module Install

end #module Roll

