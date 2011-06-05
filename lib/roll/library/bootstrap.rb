class Library

  # Setup the ledger.
  #
  def self.bootstrap(name=nil)
    require_without_rolls 'roll/ruby'

    $LOAD_STACK = []
    $LOAD_CACHE = {}

    ledger = Hash.new{|h,k| h[k] = []}

    $LOAD_GROUP = Environment.new(name) # current if name is nil.

    $LOAD_GROUP.each do |data|
      name = data[:name]     || data['name']
      path = data[:location] || data['location']
      unless File.directory?(path)
        warn "invalid path for #{name} -- #{path}"
        next
      end
      library = Library.new(path, data)
      ledger[name] << library unless data[:omit]
    end

    # Legacy mode manages a traditional loadpath.
    if LEGACY
      ledger.each do |name, libs|
        sorted_libs = [libs].flatten.sort
        lib = sorted_libs.first
        lib.absolute_loadpath.each do |path|
          $LOAD_PATH.unshift(path)
        end
      end
    end

    ledger['site_ruby'] = SiteRubyLibrary.new
    ledger['ruby']      = RubyLibrary.new

    $LEDGER = ledger
  end

end
