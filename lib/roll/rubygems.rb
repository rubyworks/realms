module Roll

  # RubyGems related control functions. This module extends
  # the Roll namespace.
  #
  module RubyGems

    #
    # Is this location a gem home location?
    #
    def gemspec?(location)
      #return true if Dir[File.join(location, '*.gemspec')].first
      pkgname = ::File.basename(location)
      gemsdir = ::File.dirname(location)
      specdir = ::File.join(File.dirname(gemsdir), 'specifications')
      gemspec = ::Dir[::File.join(specdir, "#{pkgname}.gemspec")].first
    end

    #
    # Does the current roll include any entires that lie within
    # the current gem home?
    #
    def gem_path?(path)
      dir = ENV['GEM_HOME'] || gem_home
      rex = ::Regexp.new("^#{Regexp.escape(dir)}\/")
      rex =~ path
    end

    #
    # Default gem home directory path.
    #
    # @return [String] Gem home path.
    #
    def gem_home
      if defined? RUBY_FRAMEWORK_VERSION then
        File.join File.dirname(CONFIG["sitedir"]), 'Gems', CONFIG["ruby_version"]
      elsif CONFIG["rubylibprefix"] then
        File.join(CONFIG["rubylibprefix"], 'gems', CONFIG["ruby_version"])
      else
        File.join(CONFIG["libdir"], ruby_engine, 'gems', CONFIG["ruby_version"])
      end
    end

    #
    # Lock rolls that contain locations relative to the current gem home.
    #
    # @return [Array<String>] list of roll files that were re-locked
    #
    def lock_gem_rolls
      relock = []

      locked_rolls.each do |file|
        File.each_line do |path|
          path = path.strip
          if gem_path?(path)
            relock << file
            break
          end
        end
      end

      relock.each do |file|
        lock(file)
      end

      relock
    end
  end

  extend RubyGems
end


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

