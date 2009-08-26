# = plugin.rb
#
# Development Notes:
#
# TODO This still needs love. It should work more like Library ultimately.

# Straighfoward, flexible and reuable plugin system.

module Plugin

  # Lookup pugins.

  def plugins(glob)
    glob = File.join(Config::CONFIG['datadir'], 'ruby', 'plugins', glob)
    Dir.glob(glob)
  end

  # Does plugin exist?

  def has_plugin?(glob)
    !plugins(glob).empty?
  end

  # Require plugin(s).

  def require_plugin(glob)
    plugs = []
    #files = plugins(glob)
    glob = File.join(Config::CONFIG['datadir'], 'ruby', 'plugins', glob)
    files = Dir.glob(glob)
    files.each { |file| plugs.concat(File.read_list(file)) }
    plugs.each { |plug| require plug }
  end

  # Load plugin(s).

  def load_plugin( glob )
    plugins = []
    files = plugins(glob)
    files.each { |file| plugins.concat(File.read_list(file)) }
    plugins.each { |plugin| load plugin }
  end

  # TODO import plugin?

end


class Object
  include Plugin
end
