module Rolll

  class Library

    # LibFile class represents a single file in a library.
    class LibFile < Object

      attr_reader :library, :loadpath, :filename, :extension

      #
      def initialize(library, loadpath, filename, extension=nil)
        @library   = library
        @loadpath  = loadpath
        @filename  = filename
        @extension = extension
      end

      # Library location.
      def location
        library.location
      end

      #
      def fullname
        ::File.join(location, loadpath, filename + (extension || ''))
      end

      #
      def localname
        ::File.join(filename + (extension || ''))
      end

      #
      def acquire(opts={})
        if opts[:load]
          load(opts[:wrap])
        else
          require
        end
      end

      #
      def require(options={})
        if library.name == 'ruby'
          return false if $".include?(localname)  # ruby 1.8 does not use absolutes
          $" << localname # ruby 1.8 does not use absolutes
        end

        Library.load_stack << library
        begin
          library.activate unless options[:force]
          success = require_without_rolls(fullname)
        rescue LoadError => load_error  # TODO: deativeate this if $DEBUG ?
          raise clean_backtrace(load_error)
        ensure
          Library.load_stack.pop
        end
        success
      end

      #
      def load(options={})
        if library.name == 'ruby'
          $" << localname # ruby 1.8 does not use absolutes
        end
 
        Library.load_stack << library
        begin
          library.activate unless options[:force]
          success = load_without_rolls(fullname)
        rescue LoadError => load_error
          raise clean_backtrace(load_error)
        ensure
          Library.load_stack.pop
        end
        success
      end

      #
      def ==(other)
        fullname == other.fullname
      end

      #
      def eql?(other)
        fullname == other.fullname
      end

      #
      def hash
        fullname.hash
      end

      #
      def to_s  ; fullname; end

      #
      def to_str; fullname; end
    end

  end

end
