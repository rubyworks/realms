# Realms 
# Copyright (c) 2013 Rubyworks
# BSD-2-Clause License
#
# encoding: utf-8

module Realms

  # Library class encapsulates a location on disc that contains a Ruby
  # project, with loadable features, of course.
  #
  class Library

    #
    # New Library object.
    #
    # If data is given it must have `:name` and `:version`. It can
    # also have `:loadpath`, `:date`, and `:omit`.
    #
    # @param location [String]
    #   Expanded file path to library's root directory.
    #
    # @param metadata [Hash]
    #   Overriding matadata (to circumvent loading it from `.index` or `.gemspec` file).
    #
    def initialize(location, metadata=nil)
      raise TypeError, "not a directory - #{location}" unless File.directory?(location)

      # TODO: Use `File.expand_path` on location?
      @location = location.to_s

      if metadata
        metadata[:location] = location
        @metadata = Metadata.new(metadata)
      else
        @metadata = Metadata.new(location)
      end

      validate!
    end

    #
    #
    #
    def validate!
      raise ValidationError, "Non-conforming library (missing name) -- `#{location}'"  unless name
      raise ValidationError, "Non-conforming library (missing version) -- `#{location}'" unless version
    end

    #
    # Activate the library, marking a flag indicating that the library
    # has been utilized.
    #
    # @return [true]
    #
    def activate
      @active = true

      #current = $LOAD_MANAGER[name]

      #if Library === current
      #  raise VersionConflict.new(self, current) if current != self
      #else
      #  $LOAD_MANAGER[name] = self
      #end

      ## TODO: activate runtime requirements?
      ##verify
    end

=begin
  #
  # Take requirements and activate them. This will reveal any
  # version conflicts or missing dependencies.
  #
  # @param [Boolean] development
  #   Include development dependencies?
  #
  def verify(development=false)
    reqs = development ? requirements : runtime_requirements
    reqs.each do |req|
      name, constraint = req['name'], req['version']
      Library.activate(name, constraint)
    end
  end
=end

    #
    # Is this library active in global ledger?
    #
    def active?
      @active
      #$LOAD_MANAGER[name] == self
    end

    #
    # Location of library files on disc.
    #
    def location
      @location
    end

    #
    # Access to library metadata. Metadata is gathered from
    # the `.index` file or a `.gemspec` file.
    #
    # @return [Metadata] metadata object
    #
    def metadata
      @metadata
    end

    #
    # Library's "unixname".
    #
    # @return [String] name of library
    #
    def name
      metadata.name
    end

    #
    # Library's version number.
    #
    # @return [Version::Number] version number
    #
    def version
      metadata.version
    end

    #
    # Release date.
    #
    # @return [Time] library's release date
    #
    def date
      metadata.date
    end

    #
    # Alias for +#date+.
    #
    alias_method :released, :date
    alias_method :release_date, :date

    #
    #
    #
    def paths
      metadata.paths
    end

    #
    # Library's internal load path(s). This will default to `['lib']`
    # if not otherwise given.
    #
    # @return [Array] list of load paths
    #
    def lib_paths
      metadata.lib_paths
    end

    #
    # Returns a list of load paths expand to full path names.
    #
    # @return [Array<String>] list of expanded load paths
    #
    def load_path
      @load_paths ||= lib_paths.map{ |path| File.realpath(File.join(location, path)) }
      #metadata.load_path
    end

    alias_method :loadpath, :load_path

    #
    # Library's requirements. Note that in gemspec terminology these are
    # called *dependencies*.
    #
    # @return [Array] list of requirements
    #
    def requirements
      metadata.requirements || []
    end

    #
    # Runtime requirements.
    #
    # @return [Array] list of runtime requirements
    #
    def runtime_requirements
      requirements.select{ |req| !req['development'] }
    end

    #
    # Omit library from use?
    #
    # @return [Boolean] If true, omit library from use.
    #
    def omit?
      ! @metadata.active?
    end

# TODO: Should these should come from metadata.

    #
    # Location of executable. This is alwasy bin/. This is a fixed
    # convention, unlike lib/ which needs to be more flexable.
    #
    def bindir
      ::File.join(location, 'bin')
    end

    #
    # Is there a `bin/` location?
    #
    def bindir? 
      ::File.exist?(bindir)
    end

    #
    # Location of library system configuration files.
    # This is alwasy the `etc/` directory.
    #
    def confdir
      ::File.join(location, 'etc')
    end

    #
    # Is there a `etc/` location?
    #
    def confdir?
      ::File.exist?(confdir)
    end

    #
    # Location of library shared data directory.
    # This is always the `data/` directory.
    #
    def datadir
      ::File.join(location, 'data')
    end

    # Is there a `data/` location?
    def datadir?
      ::File.exist?(datadir)
    end

    #
    # Load feature form library.
    #
    def load(pathname, options={})
      stacked = ($LOAD_STACK.last == self)

      stash_path = $LOAD_PATH
      $LOAD_STACK << self unless stacked
      $LOAD_PATH.replace(load_path)
      begin
        success = load_without_realms(pathname, options[:wrap])
      rescue LoadError
        root, subpath = File.split_root(pathname)
        success = load_without_realms(subpath, options[:wrap])
      ensure
        $LOAD_PATH.replace(stash_path)
        $LOAD_STACK.pop unless stacked
      end
      success
    end

    #
    # Requre feature from library.
    #
    def require(pathname, options={})
      stacked = ($LOAD_STACK.last == self)

      stash_path = $LOAD_PATH
      $LOAD_STACK << self unless stacked
      $LOAD_PATH.replace(load_path)
      begin
        success = require_without_realms(pathname)
      rescue LoadError
        root, subpath = File.split_root(pathname)
        success = require_without_realms(subpath, options[:wrap])
      ensure
        $LOAD_PATH.replace(stash_path)
        $LOAD_STACK.pop unless stacked
      end
      success
    end

    #
    # Does a library contain a relative +file+ within it's loadpath.
    # If so return the file, otherwise +false+.
    #
    # @param [#to_s] file
    #   The relative pathname of the file to find.
    #
    # @param [Hash] options
    #   The Hash of optional settings to adjust search behavior.
    #
    # @option options [Boolean] :suffix
    #   Automatically try standard extensions; `true` by default.
    #
    # @option options [Boolean] :outer
    #   Do not match relative to library's inner +name+ directory, eg. `lib/foo/*`.
    #
    # @option options [Boolean] :inner
    #   Do not match relative to library's outer directory, eg. `lib/*`.
    #
    # @return [String,NilClass]
    #   The absolute file path to the feature, if found.
    #
    def find(pathname, options={})
      suffix = options.key?(:suffix) ? options[:suffix] : true

      # TODO: Why not just add '' to Utils.suffixes ?
      suffix = false if Utils.suffixes.include?(::File.extname(pathname)) 

      inner  = options[:inner]
      outer  = options[:outer]

      raise ArgumentError, "nothing to search without inner or outer" if inner && outer

      suffixes = suffix ? Utils.suffixes : ['']

      loadpath.each do |lpath|
        suffixes.each do |ext|
          f = ::File.join(lpath, pathname + ext)
          return f if ::File.file?(f)
        end
      end unless inner

      inner_loadpath.each do |lpath|
        suffixes.each do |ext|
          f = ::File.join(lpath, pathname + ext)
          return f if ::File.file?(f)
        end
      end unless outer

      nil
    end

    #
    # Search load paths for glob pattern.
    #
    # @return [Array] List of matching paths.
    #
    def search(pattern, options={})
      matches = []
      load_path.each do |path|
        list = Dir.glob(File.join(path, match))
        list = list.map{ |d| d.chomp('/') }
        matches.concat(list)
      end
      matches
    end

    #
    # Alias for #find_feature.
    #
    alias_method :include?, :find

    #
    #
    #
    def legacy?
      ! inner_loadpath.empty?
    end

    #
    # What is `inner_loadpath`? Well, library doesn't require you to put your
    # library's scripts in a named lib path, e.g. `lib/foo/`. Instead one can
    # just put them in `lib/` b/c Library keeps things indexed by honest to
    # goodness library names. The `legacy_path` then is used to handle these
    # old style paths along with the new.
    #
    def inner_loadpath
      @inner_loadpath ||= (
        path = []
        loadpath.each do |lp|
          dir = File.join(lp, name)
          #dir = File.join(location, llp)
          path << dir if File.directory?(dir)
        end
        path
      )
    end

    #
    # Inspect library instance.
    #
    def inspect
      if version
        %[#<Library #{name}/#{version} @location="#{location}">]
      else
        %[#<Library #{name} @location="#{location}">]
      end
    end

    #
    # Same as #inspect.
    #
    def to_s
      inspect
    end

    #
    # Compare by version.
    #
    # @todo Raise error if name is not the same?
    #
    def <=>(other)
      version <=> other.version
    end

    #
    # Return default feature. This is the feature that has same name as
    # the library itself.
    #
    def main
      @main ||= find(name, :main=>true)
    end

    #
    #def to_rb
    #  to_h.inspect
    #end

    #
    # Convert to hash.
    #
    # @return [Hash] The primary library metadata in a hash.
    #
    def to_h
      {
        'location'     => location,
        'name'         => name,
        'version'      => version.to_s,
        'paths'        => paths,
        'date'         => date.to_s,
        'requirements' => requirements
      }
    end

  end

end




=begin
module Library

  #
  # Activate a library.
  #
  # @return [true,false] Has the library has been activated?
  #
  def activate
    current = $LOAD_MANAGER[name]

    if Library === current
      raise VersionConflict.new(self, current) if current != self
    else
      ## NOTE: we are only doing this for the sake of autoload
      ## which does not honor a customized require method.
      #if Library.autoload_hack?
      #  absolute_loadpath.each do |path|
      #    $LOAD_PATH.unshift(path)
      #  end
      #end
      $LOAD_MANAGER[name] = self
    end

    # TODO: activate runtime requirements?
    #verify
  end

  #
  # Take requirements and activate them. This will reveal any
  # version conflicts or missing dependencies.
  #
  # @param [Boolean] development
  #   Include development dependencies?
  #
  def verify(development=false)
    reqs = development ? requirements : runtime_requirements
    reqs.each do |req|
      name, constraint = req['name'], req['version']
      Library.activate(name, constraint)
    end
  end

  #
  # Is this library active in global ledger?
  #
  def active?
    $LOAD_MANAGER[name] == self
  end

end
=end
