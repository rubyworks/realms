module Roll

  module Shell

    #
    # Copy roll file.
    #
    def copy
      opts = {}

      op.banner = "Usage: roll copy [to]\n" +
                  "       roll copy [from] [to]" 
      op.separator "Copy a roll."
      op.on('--lock', '-l', "Lock after copying.") do
        opts[:lock] = true
      end
      op.on('--force', '-f', "Force overwrite of pre-existing roll.") do
        opts[:force] = true
      end

      parse

      src, dst = *argv

      fdst = Roll.copy(dst, src, opts)

      if opts[:lock]
        puts "Locked '#{dst}`."
      else
        puts "Saved '#{dst}`."
      end
    end

  end

end

