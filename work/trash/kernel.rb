#require 'facets/load/monitor' # used for debugging

#require 'roll/original'
#require 'roll/config'
#require 'roll/environment'
require 'library'
require 'library/rubylib'

Roll.bootstrap

require 'library/kernel'

=begin
module ::Kernel

  # Activate a library.
  # Same as #library_instance but will raise and error if the library is
  # not found. This can also take a block to yield on the library.
  #
  # @param name [String]
  #   the library's name
  #
  # @param constraint [String]
  #   a valid version constraint
  #
  # @return [Library] the Library instance
  def library(name, constraint=nil, &block) #:yield:
    Library.activate(name, constraint, &block)
  end

  module_function :library

  # Acquire script. This is Roll's modern require/load method.
  # It differs from the usual #require or #load primarily by
  # the fact that it will search the currently loading library,
  # i.e. the one on the top of the #LOAD_STACK, for a script
  # before looking elsewhere. The reason we can't just adjust
  # `#require` to do this is becuase it can load a local script
  # when a non-local script was intended. For example, if a 
  # project contained 'fileutils.rb' then this would be loaded
  # rather the Ruby's standard library. When using `#acquire`,
  # one has to add the `ruby/` prefix to ensure the Ruby library
  # is loaded.
  #
  # @param file [String]
  #   The script to load.
  #
  # @param options [Hash]
  #   Load options are `:wrap`, `:load`, `:legacy` and `:search`.
  #
  # @return [true, false]
  #   Was the script newly required or successfully loaded depending
  #   on the :load option settings.
  def acquire(file, options={}) #, &block)
    Library.acquire(file, options) #, &block)
  end

  module_function :acquire

  # Require script. This is the same as acquire except that the
  # `:legacy` option is fixed as `true`.
  #
  # @param file [String]
  #   The script to load, optionally prefixed with `library-name:`.
  #
  # @param options [Hash]
  #   Load options can be :wrap, :load and :search.
  #
  # @return [true, false] if script was newly required
  def require(file, options={}) #, &block)
    Library.require(file, options) #, &block)
  end

  module_function :require

  # Load script. This is the same as acquire except that the
  # `:legacy` and `:load` options are fixed as `true`.
  #
  # @param file [String]
  #   The script to load, optionally prefixed with `library-name:`.
  #
  # @param options [Hash]
  #   Load options can be :wrap and :search.
  #
  # @return [true, false] if script was successfully loaded
  def load(file, options={}) #, &block)
    Library.load(file, options) #, &block)
  end

  module_function :load

end
=end

