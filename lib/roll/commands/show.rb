module Roll

  # Show environment.
  class CommandShow < Command

    #
    def setup
      op.banner = "Usage: roll show [NAME]"
      op.separator "Show environment."
      op.on('--roll', '-r', "Show roll paths.") do
        opts[:format] = :roll
      end
      op.on('--index', '-i', "Show index listing.") do
        opts[:format] = :index
      end
      op.on('--yaml', '-y', "Dump in YAML format (implies -i).") do
        opts[:format] = :yaml
      end
    end

    #
    def call
      name = args.first
      if name and !Library.environments.include?(name)
        $stderr.puts "Environment not found."
        return
      end

      env = Library::Environment[name]
      case opts[:format]
      when :yaml
        puts env.to_yaml
      when :index
        show_libraries
      when :roll
        show_roll_file
      else
        puts env.to_s
      end
    end

    # Display roll paths. TODO: name
    def show_roll_file
      puts File.read(Ruby.roll_file).join("\n")
    end

    #
    def show_
    end

    # Show all the libraries.
    def show_libraries
      max  = ::Hash.new{|h,k| h[k]=0 }
      list = index.dup

      list.each do |data|
        data[:loadpath] = data[:loadpath].join(' ')
        data[:date]     = iso(data[:date])
        data.each do |k,v|
          max[k] = v.to_s.size if v.to_s.size > max[k]
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
      out
    end


  end

end

