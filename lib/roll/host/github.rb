require 'roll/host/base'

module Roll

  module Host

    # = Github
    #
    # TODO: How to handle username part of repository name?
    #
    class Github < Base

      def initialize(name, options={})
        super
      end

      #
      def uri
        'git://github.com/%s/%s.git' % [user, name]
      end

      #
      def scm
        @scm ||= Git.new(self, uri)
      end

    end

  end # module Host

end # module Roll

