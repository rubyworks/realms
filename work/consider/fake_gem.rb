    # TODO: Instead of supporting gemspecs as is, create a tool
    # that will add a .package file to each one.
    #
    def load_gemspec
      return false unless File.basename(File.dirname(location)) == 'gems'
      specfile = File.join(location, '..', '..', 'specifications', File.basename(location) + '.gemspec')
      if File.exist?(specfile)
        fakegem = FakeGem.load(specfile)
        self.name     = fakegem.name
        self.version  = fakegem.version
        self.loadpath = fakegem.require_paths
        true
      else
        false
      end 
    end

    # Ecapsulates the fake parsing of a gemspec.
    #
    module FakeGem
      module Gem #:nodoc:
        class Specification #:nodoc:
          attr :fake_options
          def initialize(&block)
            @fake_options = {}
            yield(self)
          end
          def method_missing(sym, *args)
            name = sym.to_s
            case name
            when /=$/
              @fake_options[name.chomp('=')] = args.first
            else
              @fake_options[name]
            end
          end
        end
        class Requirement
          def initialize(*a)
          end
        end
      end
      #
      def self.load(file)
        text = File.read(file)
        fake_spec = eval(text, binding)
        fake_spec
      end
    end

