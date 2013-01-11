module Realms

  module Shell

    # TODO: Ultimately allow for caching a different group

    #
    # Lock current roll. This caches all the neccessary information
    # about the current roll, so start-up times are much faster for
    # subsequent start-ups.
    #
    def lock
      output = nil

      op.banner = "Usage: roll lock [ROLL]"
      op.separator "Serialize ledger and save."
      #op.on('--check', '-c', "Check cache to see if it is current.") do
      #  opts[:check] = true
      #end
      op.on('--output', '-o [FILE]', "save to alternate file") do |file|
        output = file
      end

      parse

      roll = argv.first

      #if opts[:check]
      #  check
      #else
        file = Roll.lock(roll, :output=>output)
        $stdout.puts "Locked: #{file}"
      #end
    end

    # TODO: make sense any more?
    #def check(name)
    #  #result = Library::Environment.check(name)
    #  if result
    #    puts "Index for `#{name}` is in-sync."
    #  else
    #    puts "Index for `#{name}` is out-of-sync."
    #  end      
    #end

  end

end
