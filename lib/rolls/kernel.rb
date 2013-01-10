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
    Library.activate(name, constraint, &block)
  end

  module_function :library


  unless method_defined?(:require_without_library)

    class << self
      alias require_without_rolls require
      alias load_without_rolls    load
    end

    alias require_without_rolls require
    alias load_without_rolls    load

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
      $LEDGER.load(pathname, options)
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
      $LEDGER.require(pathname, options)
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
      $LEDGER.require_relative(pathname, options)
    end

    module_function :require_local

    # TODO: require_relative ?

    #
    # Acquire feature.
    #
    # @param pathname [String]
    #   The pathname of the feature to acquire.
    #
    # @param options [Hash]
    #   Load options are `:wrap`, `:load`, `:legacy` and `:search`.
    #
    # @return [true, false]
    #   Was the feature newly required or successfully loaded, depending
    #   on the `:load` option settings.
    #
    #def acquire(pathname, options={}) #, &block)
    #  $LEDGER.acquire(pathname, options) #, &block)
    #end

    #module_function :acquire

  end

end
