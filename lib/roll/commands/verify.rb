module Roll

  #
  class CommandVerify < Command

    #
    def setup
      op.banner = "Usage: roll verify [path]"
      op.separator "Verify dependencies in current environment."
    end

    # TODO: lookup root by matching .ruby relative to path?
    def call
      loc = args.first || Dir.pwd
      lib = Roll::Library.new(loc)
      if lib.requirements.empty?
        puts "Project #{lib.name} has no requirements."
      else
        lib.requirements.verify(true) # verbose
      end
      #list.each do |(name, constraint)|
      #  puts "#{name} #{constraint}"
      #end
    end

  end

end
