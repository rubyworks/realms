module Roll     #:nodoc:
class  Package  #:nodoc:
module Scm

  # = Scm Base class
  #
  # Base class for all scm systems.
  #
  class Base

    # Project name.
    attr :name

    # Local repository store location.
    attr :store

    # Repository URI
    attr :uri

    #
    def initialize(name, ioc={})
      @name = name

      @version = ioc[:version]
      @store   = ioc[:store]
      @uri     = ioc[:uri]
    end

    # Version.
    #
    def version
      @version ||= versions.max{ |a,b| natcmp(a, b, true) }
    end

    # Version type is either :tag, :branch, :revision, or :version.
    #def type
    #end

    # Location to install project.
    def destination
      File.join(store, name, version)
    end

    # Origin is the install location of the current development
    # repository, should it be needed (eg. the "trunk" or "master").
    #
    def origin
      @origin ||= File.join(store, name, '0')
    end

    #
    def system(cmd)
      if $PRETEND
        puts cmd
      else
        super(cmd)
      end
    end

    #
    def natcmp(str1, str2, caseInsensitive=false)
      str1 = str1.dup
      str2 = str2.dup
      compareExpression = /^(\D*)(\d*)(.*)$/

      if caseInsensitive
        str1.downcase!
        str2.downcase!
      end

      # remove all whitespace
      str1.gsub!(/\s*/, '')
      str2.gsub!(/\s*/, '')

      while (str1.length > 0) or (str2.length > 0) do
        # Extract non-digits, digits and rest of string
        str1 =~ compareExpression
        chars1, num1, str1 = $1.dup, $2.dup, $3.dup
        str2 =~ compareExpression
        chars2, num2, str2 = $1.dup, $2.dup, $3.dup
        # Compare the non-digits
        case (chars1 <=> chars2)
          when 0 # Non-digits are the same, compare the digits...
            # If either number begins with a zero, then compare alphabetically,
            # otherwise compare numerically
            if (num1[0] != 48) and (num2[0] != 48)
              num1, num2 = num1.to_i, num2.to_i
            end
            case (num1 <=> num2)
              when -1 then return -1
              when 1 then return 1
            end
          when -1 then return -1
          when 1 then return 1
        end # case
      end # while

      # strings are naturally equal.
      return 0
    end

  end#class Base

end#module Scm
end#module Package
end#module Roll

