module Roll

  #
  class CommandLock < Command

    # TODO: Ultimately allow for caching a different group
    def setup
      op.banner = "Usage: roll cache [ROLL-FILE]"
      op.separator "Cache load group."
      #op.on('--check', '-c', "Check cache to see if it is current.") do
      #  opts[:check] = true
      #end
      op.on('--output', '-o [FILE]', "store cache in given file") do |file|
        opts[:output] = file
      end
    end

    #
    def call
      #if opts[:check]
      #  check
      #else
        file = Roll.lock(args.first, :output=>opts[:output])
        $stdout.puts "Locked `#{file}'"
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
