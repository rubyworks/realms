# TODO: Con't use module_function, but define the class methods and have the instance methods call those.

#require 'library' # this must be loaded in first

$RUBY_IGNORE_CALLERS ||= []
$RUBY_IGNORE_CALLERS << /#{__FILE__}/  # TODO: should this be more general, e.g. File.dirname(__FILE__) ?

module ::Kernel

  #
  # In which library is the current file participating?
  #
  # @return [Library] The library currently loading features.
  #
  def __LIBRARY__
    $LOAD_STACK.last
  end

  #
  # Activate a library, same as `Library.instance` but will raise and error
  # if the library is not found. This can also take a block to yield on the
  # library.
  #
  # @param name [String]
  #   The library's name.
  #
  # @param constraint [String]
  #   A valid version constraint.
  #
  # @return [Library] The Library instance.
  #
  def library(name, constraint=nil, &block) #:yield:
    $LOAD_MANAGER.activate(name, constraint, &block)
  end

  module_function :library


  unless method_defined?(:require_without_realms)

    class << self
      alias require_without_realms require
      alias load_without_realms    load
    end

    alias require_without_realms require
    alias load_without_realms    load

    #
    # Load feature.
    #
    # @param pathname [String]
    #   The pathname of the feature to load.
    #
    # @param options [Hash]
    #   Load options can be :wrap and :search.
    #
    # @return [true, false] if feature was successfully loaded
    #
    def load(pathname, options={})
      $LOAD_MANAGER.load(pathname, options)
    end

    module_function :load

    #
    # Require feature.
    #
    # @param pathname [String]
    #   The pathname of the feature to require.
    #
    # @param options [Hash]
    #   Load options can be `:wrap`, `:load` and `:search`.
    #
    # @return [true,false] if feature was newly required
    #
    def require(pathname, options={})
      $LOAD_MANAGER.require(pathname, options)
    end

    module_function :require

    #
    # Require relative to current library.
    # @param pathname [String]
    #   The pathname of the feature to acquire.
    #
    # @param options [Hash]
    #   Acquire options.
    #
    # @return [true, false]
    #   Was the feature newly required.
    #
    def require_local(pathname, options={})
      $LOAD_MANAGER.require_relative(pathname, options)
    end

    module_function :require_local

    # TODO: Do we need to do anything with require_relative ?


    #module_function :acquire

  end

end

class Module
  private

  #
  # Acquire feature.
  #
  # @param pathname [String]
  #   The pathname of the feature to acquire.
  #
  # @param options [Hash]
  #   Aquire options (if any).
  #
  # @return [true,false]
  #   Was the feature newly acquired or not.
  #
  def acquire(pathname, options={}) #, &block)
    $LOAD_MANAGER.acquire(self, pathname, options) #, &block)
  end

end

