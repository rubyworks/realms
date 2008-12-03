module Roll

  class Library

    # = Ledger
    #
    class Ledger
      include Enumerable

      attr :path

      attr :list

      #
      def initialize(path)
        @path = path
        read
      end

      #
      def read
        @list = (
          if File.exist?(path) 
            list = File.read(path).split(/\s*\n/)
            list.reject!{ |l| l =~ /^\#/ }
          else
            list = []
          end
          list
        )
      end

      #
      def save
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'wb') do |f|
          f << list.join("\n")
        end
      end

      #
      def each(&block)
        @list.each(&block)
      end

      #
      def size
        @list.size
      end

      #
      def method_missing(s, *a, &b)
        @list.__send__(s, *a, &b)
      end

    end#class Ledger

  end#class Library

end#module Roll

