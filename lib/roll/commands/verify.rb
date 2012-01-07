module Roll

  # Verify that a project's requirements are in the current roll call.
  class CommandVerify < Command
    #
    def setup
      op.banner = "Usage: roll verify [path]"
      op.separator "Verify dependencies in current roll."
    end

    # TODO: lookup root by matching .ruby relative to path?
    def call
      location = args.first || Dir.pwd

      lib  = Library.new(location)

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
