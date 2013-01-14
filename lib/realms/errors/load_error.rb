module Realms
  class Library

    # Library::LoadError is a subclass of Ruby's standard LoadError class,
    # modified slightly to provide better error messages.
    #
    class LoadError < ::LoadError

      #
      # Setup new LoadError instance.
      #
      def initialize(failed_path, library_name=nil)
        super()

        @failed_path  = failed_path
        @library_name = library_name

        if library_name
          @message = "#{@library_name}:#{@failed_path}"
        else
          @message = failed_path
        end

        clean_backtrace
      end

      #
      # Error message string.
      #
      def to_s
        "LoadError: cannot load such file -- #{@message}"
      end

      #
      # Take an +error+ and remove any mention of 'library' from it's backtrace.
      # Will leaving the backtrace untouched if $DEBUG is set to true.
      #
      def clean_backtrace
        return if ENV['debug'] || $DEBUG
        bt = backtrace
        bt = bt.reject{ |e| $RUBY_IGNORE_CALLERS.any?{ |re| re =~ e } } if bt
        set_backtrace(bt)
      end
    end

  end
end
