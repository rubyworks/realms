if not defined?(Gem)

  module Gem
    # Some libraries, such as RDoc search through
    # all libraries for plugins using this method.
    # If RubyGems is not being used, then Rolls
    # emulates it.
    #
    #  Gem.find_files('rdoc/discover')
    #
    # TODO: Perhaps it should override if it exists
    # and call back to it on failuer?
    def self.find_files(path)
      ::Library.search(path).map{ |f| f.to_s }
    end
  end

end

