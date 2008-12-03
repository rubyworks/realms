# = Library Qua-Class
#
# The Library qua-class serves as the library manager,
# storing a ledger of available libraries.
#
class << Library

=begin
  #
  def live_load
    find(search_depth, *$LOAD_SITE)
  end

  #
  def find(depth, *paths)
    return [] if depth == 0
    loc = []
    while path = paths.shift
      next unless File.directory?(path)
      d = Dir.new(path)
      begin
        while f = d.read
          if f == '.roll'
            loc << path
            break
          elsif f[0] == ?.
            next
          elsif File.directory?(abs = File.join(path,f))
            loc.concat(find(depth-1, abs))
          end
        end
      ensure
        d.close
      end
    end
    loc
  end
=end


  # Load roll file. A roll file (.roll) is a simply
  # key = value formatted file. The assignment
  # divider can be either an '=' or a ':'. YAML was not
  # used here becuase Ruby does not load YAML by default
  # and I wanted to honor that --though I secretly think
  # it would be cool if YAML were integrated. Becuase YAML
  # is not being used, the libpath and loadpath parameter
  # are simply /[:;,]/-separated strings.
  def load_rollfile(location)
    data = {}

    find = File.join(location,'{.config/roll.ini,.roll}')
    rollfile = Dir.glob(find).first  # TODO: deprecate .roll

    return data unless rollfile

    content = File.read(rollfile)
    entries = content.split("\n")
    entries.each do |entry|
      next if /^#/.match(entry)  # skip comment lines
      i = entry.index('=') || entry.index(':')
      key, value = entry[0...i], entry[i+1..-1]
      data[key.strip.downcase.to_sym] = value.strip
    end
    data[:libpath]  = data[:libpath].split(/[:;,]/)   if data[:libpath]
    data[:loadpath] = data[:loadpath].split(/[:;,]/) if data[:loadpath]
    data
  end


  # Update cache.
  def update_cache
    setup(true) # live setup
    FileUtils.mkdir_p(File.dirname(CACHE_FILE))
    File.open(CACHE_FILE, 'w') do |f|
      f << locations.join("\n")
    end
  end

  #     #if versions.empty?
  #     #  @ledger[name] ||= Library.new(dir, :name=>name, :version=>'0') #Version.new('0', dir)

  #     # Scan current working location to see if there's
  #     # a library. This will ascend from the current
  #     # working directy to one level below root looking
  #     # for a lib/ directory.
  #     #--
  #     # TODO CHANGE TO LOOK FOR INDEX FILE.
  #     #++
  #     def scan_working
  #       paths = Dir.pwd.split('/')
  #       (paths.size-1).downto(1) do |n|
  #         dir = File.join( *(paths.slice(0..n) << 'lib') )
  #         if File.directory? dir
  #           $LOAD_SITE.unshift dir
  #         end
  #       end
  #     end

end

