# TODO: Should we use loabable, instead of overriding Kernel methods directly?

require 'loadable'

module Roll

  class Loader
    include Loadable

    #
    def call(fname, options={})
      file = Library.find(path, options)
p file
    end

    #
    def each(options={}, &block)
      ledger.each do |name, lib|
        lib = lib.sort.first if Array===lib
        lib.loadpath.each do |path|
          #path = File.join(lib.location, path)
          traverse(path, &block)
        end
      end
    end

  end

end
