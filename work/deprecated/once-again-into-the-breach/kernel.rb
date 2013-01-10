$RUBY_IGNORE_CALLERS ||= []
$RUBY_IGNORE_CALLERS << /#{__FILE__}/  # TODO: should this be more general, e.g. File.dirname(__FILE__) ?

module ::Kernel

  class << self
    alias __require__ require
    alias __load__    load
  end

  alias __require__ require
  alias __load__    load

  #
  # Acquire feature - This is Roll's modern require/load method.
  # It differs from the usual `#require` or `#load` primarily by
  # the fact that it will search the current loading library,
  # i.e. the one belonging to the feature on the top of the
  # #LOAD_STACK, before looking elsewhere. The reason we can't 
  # adjust `#require` to do this is becuase it could load a local
  # feature when a non-local feature was intended. For example, if
  # a library contained 'fileutils.rb' then this would be loaded
  # rather the Ruby's standard library. When using `#acquire`,
  # one would have to use the `ruby/` prefix to ensure the Ruby
  # library gets loaded.
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
  def acquire(pathname, options={}) #, &block)
    Ledger.acquire(pathname, options) #, &block)
  end

  module_function :acquire

  #
  # Require feature - This is the same as acquire except that the
  # `:legacy` option is fixed as `true`.
  #
  # @param pathname [String]
  #   The pathname of the feature to require.
  #
  # @param options [Hash]
  #   Load options can be `:wrap`, `:load` and `:search`.
  #
  # @return [true,false] if feature was newly required
  #
  def require(pathname, options={}) #, &block)
    Ledger.require(pathname, options) #, &block)
  end

  module_function :require

  #
  # Load feature - This is the same as acquire except that the
  # `:legacy` and `:load` options are fixed as `true`.
  #
  # @param pathname [String]
  #   The pathname of the feature to load.
  #
  # @param options [Hash]
  #   Load options can be :wrap and :search.
  #
  # @return [true, false] if feature was successfully loaded
  #
  def load(pathname, options={}) #, &block)
    Ledger.load(pathname, options) #, &block)
  end

  module_function :load

end
