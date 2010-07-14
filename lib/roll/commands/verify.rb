module Roll

  #
  class CommandVerify < Command

    #
    def setup
      op.banner = "Usage: roll verify"
      op.separator "Verify dependencies in current environment."
    end

    # TODO: lookup root instead of Dir.pwd
    def call
      lib = Roll::Library.new(Dir.pwd)
      if lib.requirements.empty?
        puts "Project #{lib.name} has no requirements."
      else
        lib.requirements.verify(true) # verrbose
      end
      #list.each do |(name, constraint)|
      #  puts "#{name} #{constraint}"
      #end
    end

  end

end
