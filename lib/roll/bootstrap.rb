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

    # TODO: fallback measure would put all libs on loadpath ?
    #if ENV['ROLLOLD']
    #  @index.each do |name, libs|
    #    sorted_libs = [libs].flatten.sort
    #    lib = sorted_libs.first
    #    lib.loadpath.each do |lp|
    #      $LOAD_PATH.unshift(File.join(lib.location, lp))
    #    end
    #  end
    #end

    ledger['site_ruby'] = SiteRubyLibrary.new
    ledger['ruby']      = RubyLibrary.new

    $LEDGER = ledger
  end

end
