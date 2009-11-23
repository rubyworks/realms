module Roll
  require 'roll/ledger'

  #
  module Manageable

    #
    def ledger
      @ledger ||= Ledger.new
    end

    #
    def list
      ledger.names
    end

    #
    def load_stack
      ledger.load_stack
    end

    #
    def require(path)
      ledger.require(path)
    end

    #
    def load(path, wrap=nil)
      ledger.load(path, wrap)
    end

    # Get an instance of a library by name, or name and version.
    # Libraries are singleton, so once loaded the same object is
    # always returned.

    def instance(name, constraint=nil)
      name = name.to_s

      #raise "no library -- #{package}" unless ledger.include?(package)
      return nil unless ledger.include?(name)

      library = ledger[name]

      if Library===library
        if constraint # TODO: it's okay if constraint fits current
          raise VersionConflict, "previously selected version -- #{ledger[name].version}"
        else
          library
        end
      else # library is an array of versions
        if constraint
          compare = Version.constraint_lambda(constraint)
          version = library.select(&compare).max
        else
          version = library.max
        end
        unless version
          raise VersionError, "no library version -- #{package} #{constraint}"
        end
        #ledger[package] = version
        version.activate
      end
    end

    # A shortcut for #instance.

    alias_method :[], :instance

    # Same as #instance but will raise and error if the library is
    # not found. This can also take a block to yield on the library.

    def open(name, constraint=nil) #:yield:
      lib = instance(name, constraint)
      unless lib
        raise LoadError, "no library -- #{name}"
      end
      yield(lib) if block_given?
      lib
    end

  end

end

