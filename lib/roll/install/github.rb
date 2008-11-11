require 'roll/install/host'

module Roll

  module Install

    # = Github
    #
    # TODO: How to handle user part of repository?
    class Github < Host

      def initialize(name, options={})
        super
      end

      #
      def uri
        'git://github.com/%s/%s.git' % [user, name]
      end

      #
      def scm
        @scm ||= Git.new(self, :uri=>uri)
      end
    end

  end

end
