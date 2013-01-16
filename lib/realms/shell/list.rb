module Realms
  class Library
    module Shell
      register :list

      #
      # List available libraries.
      #
      def list
        opts = {}

        op.banner = "Usage: realm list"
        op.separator "List available libraries."

        op.on('--verbose', '-v', "Show detailed listing.") do
          opts[:verbose] = true
        end

        parse

        if $LOAD_MANAGER.keys.empty?
          $stderr.puts "No libraries found."
        else
          if opts[:verbose]
            list_details
          else
            list_names
          end
        end
      end

    private

      #
      # List names of available libraries.
      #
      # @todo Currently this list names in four columns. In future it would be nice to
      # set the number of columns to max screen width. This can be done with ansi gem 
      # but it would be better if there was a built-in way to do this in Ruby.
      #
      # @return nothing
      #
      def list_names
        names = $LOAD_MANAGER.keys.sort
        if names.empty?
          puts "No libraries found."
        else
          max  = names.map{ |name| name.size }.max + 4
          rows = ((names.size + 4) / 4).to_i
          cols = []
          names.each_with_index do |name, i|
            c = i % rows
            cols[c] ||= []
            cols[c] << name
          end
          out = ""
          cols.each do |row|
            row.each do |name|
              out << ("%-#{max}s" % [name])
            end
            out << "\n"
          end
          puts out
        end
      end

      #
      # List libraries in detail with name, version, release date and location.
      #
      # @todo Add lib paths.
      #
      # @return nothing
      #
      def list_details
        max  = ::Hash.new{|h,k| h[k]=0 }
        list = []

        names = $LOAD_MANAGER.names.sort

        names.each do |name|
          next if name == 'ruby'

          libs = $LOAD_MANAGER[name]
          libs = Array(libs).sort

          libs.each do |lib|
            data = lib.to_h.rekey
            #data[:loadpath] = data[:loadpath].join(' ')
            data[:date] = Utils.iso_date(data[:date])

            data.each do |k,v|
              max[k] = v.to_s.size if v.to_s.size > max[k]
            end

            list << data
          end
        end

        max = max.values_at(:name, :version, :date, :location) #, :loadpath)

        list = list.map do |data|
          data.values_at(:name, :version, :date, :location) #, :loadpath)
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
end
