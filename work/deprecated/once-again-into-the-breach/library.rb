require 'library'
require 'library/rubylib'

# Rolls adds some convenience methods to Library's metaclass
# for interfacing with the current ledger. This provides a
# nicer API for a some uses, e.g. `Library.list`.
#
class Library

  #
  # Access to the library ledger (`$LEDGER`).
  #
  # @return [Array] The `$LEDGER` array.
  #
  def self.ledger
    $LEDGER
  end

  #
  # Library names from ledger.
  #
  # @return [Array] The keys from `$LEDGER` array.
  #
  def self.names
    $LEDGER.keys
  end

  #
  # Library names from ledger.
  #
  # @return [Array] The keys from `$LEDGER` array.
  #
  def self.list
    $LEDGER.keys
  end

  #
  # Require a feature from the library.
  #
  # @param [String] pathname
  #   The pathname of feature relative to library's loadpath.
  #
  # @param [Hash] options
  #
  # @return [true,false] If feature was newly required or successfully loaded.
  #
  def self.require(pathname, options={})
    Ledger.require(pathname, options)
  end

  #
  # Load file path. This is just like #require except that previously
  # loaded files will be reloaded and standard extensions will not be
  # automatically appended.
  #
  # @param pathname [String]
  #   pathname of feature relative to library's loadpath
  #
  # @return [true,false] if feature was successfully loaded
  #
  def self.load(pathname, options={})
    Ledger.load(pathname, options)
  end

  #
  # Roll-style loading. First it looks for a specific library via `:`.
  # If `:` is not present it then tries the current loading library.
  # Failing that it fallsback to Ruby itself.
  #
  #   require('facets:string/margin')
  #
  # To "load" the library, rather than "require" it, set the +:load+
  # option to true.
  #
  #   require('facets:string/margin', :load=>true)
  #
  # @param pathname [String]
  #   pathname of feature relative to library's loadpath
  #
  # @return [true, false] if feature was newly required
  #
  def self.acquire(pathname, options={})
    Ledger.acquire(pathname, options)
  end

  #
  # A shortcut for #instance.
  #
  # @return [Library,NilClass] The activated Library instance, or `nil` if not found.
  #
  def self.[](name, constraint=nil)
    $LEDGER.activate(name, constraint) if $LEDGER.key?(name)
  end

  #
  # Get an instance of a library by name, or name and version.
  # Libraries are singleton, so once loaded the same object is
  # always returned.
  #
  # @todo This method might be deprecated.
  #
  # @return [Library,NilClass] The activated Library instance, or `nil` if not found.
  #
  def self.instance(name, constraint=nil)
    $LEDGER.activate(name, constraint) if $LEDGER.key?(name)
  end

  #
  # Activate a library. Same as #instance but will raise and error if the
  # library is not found. This can also take a block to yield on the library.
  #
  # @param [String] name
  #   Name of library.
  #
  # @param [String] constraint
  #   Valid version constraint.
  #
  # @raise [LoadError]
  #   If library not found.
  #
  # @return [Library]
  #   The activated Library object.
  #
  def self.activate(name, constraint=nil) #:yield:
    library = $LEDGER.activate(name, constraint)
    yield(library) if block_given?
    library
  end

  #
  # Like `#new`, but adds library to library ledger.
  #
  # @todo Better name for this method?
  #
  # @return [Library] The new library.
  #
  def self.add(location)
    $LEDGER.add_location(location)

    #library = new(location)
    #$LEDGER.add_library(library)
    #library
  end

end
