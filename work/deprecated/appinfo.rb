# = appinfo.rb
#
# == Notes
#
# In an ideal would the domain could be used to differentiate
# projects of the same "unix" name. Obviously that's not
# possible, but it's good for thought at least.

require 'facets/more/aobject'
require 'facets/core/module/alias_accessor'
#require 'facets/core/nilclass/to_h'

# Application Information.

# In Ratchets, this serves as the basis for Project information.
# In library.rb it serves as the basis for Library metadata.

class AppInfo < AObject

  # The title of the application (free-form, defaults to name).
  attr :title
  # One-line description of the package (Max 80 chars.)
  attr :summary
  # Detailed description of the package.
  attr :description
  # "Unix" name of the application.
  attr :name
  # Version number (eg. '1.0.0').
  attr :version
  # Build number (defaults to a number based on current date-time).
  attr :buildno
  # Status of this release: alpha, beta, RC1, etc.
  attr :status
  # Architecture this release can run on: any, i386, i686, ppc, etc.
  attr :arch
  # Date of release (defaults to Time.now).
  attr :released
  # The date the project was started.
  attr :created
  # Release code name (generally used just for fun).
  attr :codename
  # Official domain associated with this package.
  attr :domain
  # Project slogan or "trademark" phrase.
  attr :slogan
  # General one-word software category.
  attr :category
  # Distribution License.
  attr :license
  # Author(s) of this library.
  attr :author
  # Contact(s) (defaults to authors).
  attr :contact
  # Gerenal Email (if differnt from contact's).
  attr :email
  # Project's homepage.
  attr :homepage
  # Internet address(es) to downloadable packages.
  attr :download
  # Internet address for project wiki.
  attr :wiki
  # Project's mailing list or other contact email.
  attr :list
  # Source code repository location (http:// or ftp://, etc.)
  attr :repo
  # Specifices the type of version control system used for this repo.
  # Controllers include: darcs, svn, cvs, etc.
  attr :scm
  # Public key file associated with this library. This is useful
  # for security purposes especially remote loading. [PUBKEY.PEM]
  attr :public_key
  # Files in this package that are executables.
  attr :executables
  # Files in this package that are public reusable APIs.  (#attr :scope)
  attr :libraries
  # What other packages does this package need in order to function.
  attr :dependencies
  # What other packages should be used with this package.
  attr :recommends
  # What other packages would be useful with this package.
  attr :suggests
  # What other packages does this package conflict.
  attr :conflicts
  # What other packages does this package replace.
  attr :replaces
  # What other package(s) does this package provide the same dependecy fulfilment.
  # For example, a package 'bar-plus' might fulfill the same dependency criteria
  # as package 'bar', so 'bar-plus' is said to provide 'bar'.
  attr :provides
  # What other packages does this package need to build/install.
  #attr :build_dependencies  # leave to dependencies itself.

  ## Aliases

  alias_accessor :architecture, :arch
  alias_accessor :platform,     :arch
  alias_accessor :repository,   :repo

  ## Defaults/Filters

  def title   ; @title   || name       ; end
  def license ; @license || 'Ruby/GPL' ; end

  def summary ; @summary[0..79] ; end

  def contact ; @author  || author  ; end
  def email   ; @contact || contact ; end

  def arch    ; @arch    || "any"   ; end
  def status  ; @status  || "alpha" ; end

  def buildno
    if TrueClass === @buildno
      Time.now.strftime("%H*60+%M")
    else
      @buildno
    end
  end

  def executables  ; @executables  || [] ; end
  def dependencies ; @dependencies || [] ; end
  def requirements ; @requirements || [] ; end
  def recommends   ; @recommends   || [] ; end
  def conflicts    ; @conflicts    || [] ; end
  def replaces     ; @replaces     || [] ; end
  def provides     ; @provides     || [] ; end

  ## Composites

  # Package name is in the form of +name-version+, or
  # +name-version-arch+ if +arch+ if it is not 'any', 'all' or nil.

  def package_name
    case arch
    when 'any', 'all', nil
      "#{name}-#{version}"
    else
      "#{name}-#{version}-#{arch}"
    end
  end

  # Validate.

  def valid?
    valid = false
    valid = false unless name
    valid = false unless version
    valid = false unless license
    valid
  end

  # Returns a standard taguri id for the library and release.

  #def taguri
  #  "tag:#{name}.#{domain},#{date}"
  #end

end

