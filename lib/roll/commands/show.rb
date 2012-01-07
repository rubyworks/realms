module Roll

  # Show environment.
  class CommandShow < Command

    #
    def setup
      op.banner = "Usage: roll show [NAME]"
      op.separator "Show environment."
      op.on('--roll', '-r', "Show list of available rolls.") do
        opts[:format] = :rolls
      end
      op.on('--ledger', '-l', "Show current ledger.") do
        opts[:format] = :ledger
      end
    end

    #
    def call
      name = args.first

      if name and !Roll.environments.include?(name)
        $stderr.puts "Environment not found."
        return
      end

      #env = Roll::Environment[name]

      case opts[:format]
      when :rolls
        puts Roll.environments.join("\n")
      when :ledger
        show_ledger
      when :roll
        show_rolls
      else
        name = args.first
        if name 
          if Roll.environments.include?(name)
          else
            $stderr.puts "Environment not found."
          end
        else
          show_roll_paths
        end
      end
    end

    # Display roll paths. TODO: name
    def show_roll_paths
      puts File.read(Roll.roll_file)
    end

    # Show all the libraries.
    def show_ledger
      max  = ::Hash.new{|h,k| h[k]=0 }
      list = []

      $LEDGER.each do |name, libs|
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

