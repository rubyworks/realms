class Library

  # The Script class represents a single file in a library.
  #
  # TODO: Err... what is extension for?
  class Script

    # Create a new Script instance.
    #
    # @param library [Library]
    #   the Library object to which the file belongs
    #
    # @param loadpath [String]
    #   the loadpath within the library in which the script resides
    #
    # @param filename [String]
    #   the file path of the script relative to the loadpath
    #
    # @param extension [Boolean]
    #   is this an extension?
    #
    def initialize(library, loadpath, filename, extension=nil)
      @library   = library
      @loadpath  = loadpath
      @filename  = filename
      @extension = extension
    end

    # The Library object to which the file belongs.
    attr_reader :library

    # The loadpath within the library in which the script resides.
    attr_reader :loadpath

    # The file path of the script relative to the loadpath.
    attr_reader :filename

    # Is this an extension?
    attr_reader :extension

    # Name of the library to which the script belongs.
    #
    # @return [String] name of the script's library
    def library_name
      Library===library ? library.name : nil
    end

    #
    def library_activate
      library.activate if Library===library
    end

    # Library location.
    #
    # @return [Sting] location of library
    def location
      Library===library ? library.location : library
    end

    # Full path name of of script.
    #
    # @return [String] expanded file path of script 
    def fullname
      @fullname ||= ::File.join(location, loadpath, filename + (extension || ''))
    end

    # The path of the script relative to the loadpath.
    #
    # @return [String] file path less location and loadpath
    def localname
      @localname ||= ::File.join(filename + (extension || ''))
    end

    # Acquire the script --Roll's advanced require/load method.
    #
    #
    def acquire(opts={})
      if wrap = opts.delete(:load) # TODO: why delete?
        load(opts[:wrap])
      else
        require
      end
    end

    # Require script.
    #
    #
    def require(options={})
      if library_name == 'ruby' or library_name == 'site_ruby'
        return false if $".include?(localname)  # ruby 1.8 does not use absolutes
        $" << localname # ruby 1.8 does not use absolutes
      end

      Library.load_stack << self #library
      begin
        library_activate unless options[:force]
        success = require_without_rolls(fullname)
      #rescue ::LoadError => load_error  # TODO: deativeate this if $DEBUG ?
      #  raise LoadError.new(localname, library_name)
      ensure
        Library.load_stack.pop
      end
      success
    end

    # Load script.
    #
    #
    def load(options={})
      if library_name == 'ruby' or library_name == 'site_ruby'
        $" << localname # ruby 1.8 does not use absolutes
      end

      Library.load_stack << self #library
      begin
        library_activate unless options[:force]
        success = load_without_rolls(fullname)
      #rescue ::LoadError => load_error
      #  raise LoadError.new(localname, library_name)
      ensure
        Library.load_stack.pop
      end
      success
    end

    # Compare this scripts full path name to another using `#==`.
    #
    # @param [Script, String] another script or file path.
    #
    # @return [true, false] if scripts are the same file
    def ==(other)
      fullname == other.to_s
    end

    # Same as `#==`.
    #
    # @param [Script, String] another script or file path.
    #
    # @return [true, false] if scripts are the same file
    def eql?(other)
      fullname == other.to_s
    end

    # Same a fullname.
    #
    # @return [String] expanded file path
    def to_s
      fullname
    end

    # Same a fullname.
    #
    # @return [String] expanded file path
    def to_str
      fullname
    end

    # Use `#fullname` to calculate a hash value for the script file.
    #
    # @return [Integer] hash value
    def hash
      fullname.hash
    end
  end

end
