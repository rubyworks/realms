class Realms::Library

  module Shell

    #
    # Show roll.
    #
    def show
      op.banner = "Usage: roll show [NAME]"
      op.separator "Show roll paths."

      parse 

      name = argv.first

      if name and !Roll.rolls.include?(name)
        $stderr.puts "Roll not found."
        return
      end

      if name 
        if !Roll.rolls.include?(name)
          $stderr.puts "Roll not found."
        else
          # TODO: 
        end
      else
        puts "# #{Roll.rollname}"
        puts File.read(Roll.roll_file)
      end
    end

  end

end

