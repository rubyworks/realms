# TITLE:
#
#   Package
#

require 'yaml'
require 'roll/package/attributes'
require 'roll/package/infoutils'

#

class Package

  include Attributes
  include InfoUtils # ??? How much needed?

  # Read package information from a YAML file.
  def self.open(file=nil, options={})
    unless file
      file = Dir.glob(filename, File::FNM_CASEFOLD).first
      raise "Manifest file is required." unless file
    end
    begin
      data = YAML::load(File.open(file))
      data.update(options)
      data.update(:file => file)
      new(data)
    rescue LoadError => e
      warn "package file failed to load -- #{file}"
      raise e if $DEBUG
    rescue => e
      warn "package file failed to load -- #{file}"
      raise e if $DEBUG
    end
  end

  # Possible file name (was for Fileable).
  def self.filename
    '{,meta/}*.{box,roll}'
  end

  # New Package. Pass in a data hash to populate the object.
  #
  # TODO Support self setter block?

  def initialize(data={}) #, &yld)
    data.each do |k,v|
      send( "#{k}=", v ) rescue nil
    end
    #if yld
    #  yld.to_h.each do |k,v|
    #    send( "#{k}=", v ) rescue nil
    #  end
    #end
    if file
      base = File.basename(file).chomp('.roll')
      if base.index('-')  # Just in case you want to load it from a non-conforming file.
        name, version = base.split('-')
        name = name.downcase # TODO Is this too restrictive?
        @name = name
        @version = version
      end
    end
    self
  end

  # Name of the roll file. # TODO Maybe change to roll_file.
  attr_accessor :file

  # Path to the library.
  def location
    return unless @file
    @location ||= (
      dir = File.dirname(@file)
      File.basename(dir) == 'meta' ? File.dirname(dir) : dir
    )
  end

  # Path to the roll file.
  def meta_location
    File.dirname(@file) if @file
  end

  # Indicates if this project information was read from a file.
  # Returns the file's name if so.
  def read? ; file ; end


  # GENERAL INFORMATION

  public

  # The title of the project (free-form, defaults to name).
  attr_accessor :title do
    @title || name
  end

  # Subtitle is limited to 60 characters.
  attr_accessor :subtitle do
    @subtitle.to_s[0..59]
  end

  # Brief one-line description of the package (Max 80 chars.)
  attr_accessor :summary, :brief do
    @summary.to_s[0..79]
  end

  # More detailed description of the package.
  attr_accessor :description

  # "Unix" name of the package.
  attr_accessor :name

  # "Unix" name of the project this package belongs
  # (default is the same as name)
  attr_accessor :project do
    @project || name
  end

  # The date the project was started.
  attr_accessor :created

  # Copyright notice.
  attr_accessor :copyright do
    @copyright || "Copyright (c) #{Time.now.strftime('%Y')} #{author}"
  end

  # Distribution License.
  attr_accessor :license do
    @license || 'GPLv3'
  end

  # Slogan or "trademark" phrase.
  attr_accessor :slogan

  # General one-word software category.
  attr_accessor :category

  # Author(s) of this project.
  # (Usually in "name <email>" format.)
  attr_accessor :author

  # Contact(s) (defaults to authors).
  attr_accessor :contact do
    @contact || author
  end

  # Gerenal Email address (defaults to first contact's address, if given).
  attr_accessor :email do
    @email || contact
  end

  # Official domain associated with this package.
  attr_accessor :domain

  # Project's homepage.
  attr_accessor :homepage

  # Project's development site.
  attr_accessor :development, :devsite

  # Internet address(es) to documentation pages.
  attr_accessor :documentation, :docs

  # Internet address(es) to downloadable packages.
  attr_accessor :download

  # Internet address for project wiki.
  attr_accessor :wiki

  # Project's mailing list or other contact email.
  attr_accessor :list, :mailinglist

  # Generate documentation on installation?
  attr_accessor :document

  # Returns a standard taguri id for the library and release.
  def project_taguri
    "tag:#{name}.#{domain},#{created}"  # or released?
  end


  # VERSION INFORMATION

  public

  # Version number (eg. '1.0.0').
  attr_accessor :version

  # Status of this release: alpha, beta, RC1, etc.
  attr_accessor :status

  # Date of release (defaults to Time.now).
  attr_accessor :released

  # Current release code name.
  attr_accessor :codename

  # Build number (if true, defaults to a number based on current date-time).
  # If buildno is set to true, than returns a time stamp.
  attr_accessor :buildno do
    bn = stamp.buildno if stamp
    unless bn
      if TrueClass === @buildno
        bn = Time.now.strftime("%H*60+%M")
      else
        bn = @buildno
      end
    end
    return bn
  end


  # PACKAGE CONTENTS
  #
  # Infromation about what is in the package.

  public

  # Files in this package that are executables.
  # These files must in the packages bin/ directory.
  # If left blank all bin/ files are included.

  attr_accessor :executable, :executables do
    return [@executable].flatten.compact if @executable
    exes = []
    dir = File.join(location, 'bin')
    if File.directory?(dir)
      Dir.chdir(dir) do
        exes = Dir.glob('*')
      end
    end
    @executable = exes
  end

  # Library files in this package that are *public*.
  # This is akin to load_path but specifies specific files
  # that can be loaded from the outside --where as those
  # not listed are considerd *private*.
  #
  # NOTE: This is not enforced --and may never be. It
  # complicates library loading. Ie. how to distinguish public
  # loading from external loading. But it something that can be
  # consider more carfully in the future. For now it can serve
  # as an optional reference.
  attr_accessor :library, :libraries do
    [@library || 'lib/**/*'].flatten
  end

  # Location(s) of executables.
  attr_accessor :bin_path, :bin_paths

  # Root location(s) of libraries (used by Rolls).
  # If you plan to support Gems, this would be something like:
  #
  #   'lib/facets'
  #
  # If not, then the default ('lib') is nice b/c it means one less
  # layer in your project heirarchy.
  attr_accessor :lib_path, :lib_paths, :load_path, :load_paths do
    [@lib_path || 'lib'].flatten
  end

  # Traditional load path (used by RubyGems).
  # The default is 'lib', which is usually fine.
  attr_accessor :gem_path, :gem_paths do
    [@gem_path || 'lib'].flatten
  end

  # Default file to load when requiring only on a package name. Eg.
  #
  #   require 'facets'
  #
  # This defaults to 'index.rb'.
  attr_accessor :index_file do
    @index_file  || 'index.rb'
  end

  # Files to generally ignore (mainly for manifest collection).
  attr_accessor :ignore do
    @ignore || %w{ .svn _darcs .config .installed }
  end

  # Root location(s) of libraries.
  #--
  # TODO This is an intersting idea. Instead of fixed locations in
  # the file system one could register "virtual locations" which map
  # to real locations. Worth the added flexability?
  #++
  #attr_accessor :register do
  #  @register    || { name => 'lib' }
  #end


  # NATIVE/COMPILATION INFORMAITION
  #
  # Native information, for compiling a library.
  #
  # TODO Platform gem support.

  public

  # TODO How to handle binary packages? How goes this work with gems building?

  # Architecture(s) this release can run on: any, i386, i686, ppc, etc.
  attr_accessor :arch, :architecture do
    @arch || "any"
  end

  # List of platforms supported, i.e operating systems. If empty,
  # then all platforms are support without special treatment.
  #attr_accessor :platform, :platforms

  # List of scripts to run to compile extensions.
  # Scripts to run to compile extensions.
  attr_accessor :compile do
    [@compile || Dir.glob(File.join(location, 'ext/**/extconf.rb'))].flatten.compact
  end

  #def platform ; [@platform || 'any'].flatten ; end


  # SECURITY INFORMATION

  public

  # Encryption digest type used.
  #   (md5, sha1, sha128, sha256, sha512).
  attr_accessor :digest do
    @digest || 'md5'
  end

  # Public key file associated with this library. This is useful
  # for security purposes especially remote loading. [pubkey.pem]
  attr_accessor :public_key do
    @public_key || 'pubkey.pem'
  end

  # Private key file associated with this library. This is useful
  # for security purposes especially remote loading. [_privkey.pem]
  attr_accessor :private_key
  #   @private_key  || '_privkey.pem'
  # end


  # SOURCE CONTROL MANAGEMENT INFORMATION
  #
  # Specify which verison control system is being used.
  # Sometimes this is autmatically detectable, but it
  # is better to specify it.

  public

  # Specifices the type of revision control system used.
  #   darcs, svn, cvs, etc.
  # Will try to determine which version control system is being used.
  attr_accessor :scm do
    return @scm unless @scm.nil?
    @scm = if File.directory?('.svn')
      'svn'
    elsif File.directory?('_darcs')
      'darcs'
    else
      false
    end
  end

  # Files that are tracked under revision control.
  # Default is all less standard exceptions.
  # '+' and '-' prefixes can be used to augment the list
  # rather than fully override it.
  attr_accessor :track, :scm_files

  # Internet address to source code repository.
  # (http://, ftp://, etc.)
  attr_accessor :repository, :repo

  # Changelog file.
  attr_accessor :changelog


  # DISTRIBIUTION INFORMATION
  #
  # This information specifies which files a repository trunk/branch
  # are to be included in general distribution of the package.

  public

  # Package formats supported (tar.gz, zip, gem, deb, etc.)
  attr_accessor :format, :formats, :packaging, :pack, :types do
    @format || ['gem', 'tgz']
  end

  # Where to store package files. Defaults to +pkg/.
  attr_accessor :store do
    @store || 'pkg'
  end

  # Where to save archival backups.
  attr_accessor :archive

  # Files to be distributed in a package. Defaults to all files
  # less standard exclusions.
  #
  # '+' and '-' prefixes can be used augment the list rather
  # than fully override it. Eg.
  #
  #   distribute: [ -rdoc ]
  #
  # If the first entry has a prefix than default selection is
  # automatically included.
  #
  # This is overridden if there is a manifest, but may also be
  # used to generate said manifest.
  attr_accessor :distribute do
    [@distribute || '**/*'].flatten.compact
  end

  # Manifest file.
  attr_accessor :manifest

  # Add version tiers to package? If true a package's lib/ and ext/ files
  # will be wrapped in a version folder. (This is specialized transfer rule.)
  #attr_accessor :tier

  # Manifest file.
  #def manifest
  #  @manifest #||= Manifest.open
  #end

  # Set manifest file, which will load it.
  def manifest=(file)
    @manifest = file
    @filelist = File.read_list(file) #Manifest.open(file)
    return file
  end

  # list of file included in a package.
  def filelist
    #manifest ? manifest.filelist : (@filelist ||= collect_files)
    @filelist ||= collect_files
  end

  # Validate that the files in the manifest actually exist.
  def validate_manifest
    missing = []
    filelist.each do |f|
      missing << f unless File.exist?(f)
    end
    unless missing.empty?
      raise ValidationError, "manifest lists non-existent files -- " + missing.join(" ")
    end
  end

  private

  # Collect distribution files.
  def collect_files( with_dirs=false )
    patterns = distribute #+ less_ignore
    matching_files = nil
    Dir.chdir(location) do
      matching_files = []
      matching_files += Dir.multiglob_with_default('**/*', distribute, :recurse=>true)
      matching_files -= Dir.multiglob_r(ignore)
    end
    unless with_dirs
      matching_files = matching_files.select{ |f| !File.directory?(f) }
    end
    return matching_files
  end

  # PACKAGING INFORMATION
  #
  # Package inter-relationship data. Generally refered to as package
  # "dependencies", but also includes +recommendations+, +suggestions+,
  # +replacements+, +provisions+, and +build-dependencies+, as well
  # as a few other fields that set a package apart from a project,
  # such as +architecture+.

  public

  # Package name. This defaults to name, but is here b/c it may
  # vary under different packagings (deb vs. gem).
  attr_accessor :package do
    @package || name
  end

  # What other packages *must* this package have in order to function.
  attr_accessor :dependency, :dependencies do
    @dependency || []
  end

  # What other packages *should* be used with this package.
  attr_accessor :recommend, :recommends, :recommendations do
    @recommend || []
  end

  # What other packages *could* be useful with this package.
  attr_accessor :suggest, :suggests, :suggestions do
    @suggest || []
  end

  # What other packages does this package conflict.
  attr_accessor :conflict, :conflicts do
    @conflict || []
  end

  # What other packages does this package replace.
  attr_accessor :replace, :replaces, :replacements do
    @replace  || []
  end

  # What other package(s) does this package provide the same dependency fulfilment.
  # For example, a package 'bar-plus' might fulfill the same dependency criteria
  # as package 'bar', so 'bar-plus' is said to provide 'bar'.
  attr_accessor :provide, :provides, :provisions do
    @provide || []
  end

  # Abirtary information about what might be needed to use this package.
  # This is strictly information for the end-user to consider.
  #   Eg. "Fast graphics card"
  attr_accessor :requirement, :requirements do
    @requirement || []
  end

  # What packages does this package need to build? (eg. 'ratch')
  attr_accessor :build_dependency, :build_dependencies do
    @build_dependency  || []
  end

  # Abirtary information about what might be needed to build this package.
  attr_accessor :build_requirement, :build_requirements do
    @build_requirement || []
  end

  # Package name is in the form of +name-version+, or
  # +name-version-arch+ if +arch+ is not 'any', 'all' or nil.
  #
  # TODO Not sure how this can work actually. What about
  # multiple architectures?
  def package_name
    case arch
    when 'any', 'all', nil
      "#{name}-#{version}"
    else
      "#{name}-#{version}-#{arch}"
    end
  end


  # VALIDATION

  validate "name is required" do
    name
  end

  validate "version is required" do
    version
  end

end

