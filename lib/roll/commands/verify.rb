module Roll

  #
  class CommandVerify < Command

    #
    def setup
      op.banner = "Usage: roll verify"
      op.separator "Verify dependencies in current environment."
    end

    #
    def call
      list = Roll.verify
      list.each do |(name, constraint)|
        puts "#{name} #{constraint}"
      end
    end

  end

end