require 'roll/package/host/base'

module Roll     #:nodoc:
module Package  #:nodoc:
module Host     #:nodoc:

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
end # module Package
end # module Roll

