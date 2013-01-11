module Realms

  module Shell

    #
    # Dump the ledger.
    #
    def ledger
      opts = {}

      op.banner = "Usage: roll ledger"
      op.separator "Show current ledger."
      op.on('-y', '--yaml', "Output in YAML format.") do
        opts[:yaml] = true
      end

      parse

      # TODO: output actual lock format, not just to_yaml
      if opts[:yaml]
        puts $LEDGER.to_yaml
        return
      end

      max  = ::Hash.new{|h,k| h[k]=0 }
      list = []

      $LEDGER.each do |name, libs|
        next if name == 'ruby'

        libs = [libs] unless Array === libs

        libs.each do |lib|
          data = lib.to_h
          data[:loadpath] = data[:loadpath].join(' ')
          #data[:date]     = iso(data[:date])

          data.each do |k,v|
            max[k] = v.to_s.size if v.to_s.size > max[k]
          end

          list << data
        end
      end

      max = max.values_at(:name, :version, :date, :location, :loadpath)

      list = list.map do |data|
        data.values_at(:name, :version, :date, :location, :loadpath)
      end

      list.sort! do |a,b|
        x = a[0] <=> b[0]
        x != 0 ? x : b[1] <=> a[1]  # TODO: use natcmp
      end
 
      mask = max.map{ |size| "%-#{size}s" }.join('  ') + "\n"

      out = ''
      list.each do |name, vers, date, locs, lpath|
        str = mask % [name, vers, date, locs, lpath]
        out << str 
      end

      puts out
    end

  end

end
