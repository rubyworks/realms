module Roll

  # Copy roll file.
  class CommandCopy < Command
    #
    def setup
      op.banner = "Usage: roll copy [to]\n" +
                  "       roll copy [from] [to]" 
      op.separator "Copy a roll."
      op.on('--lock', '-l', "Lock after copying.") do
        opts[:lock] = true
      end
      op.on('--force', '-f', "Force overwrite of pre-existing roll.") do
        opts[:force] = true
      end
    end

    #
    def call
      if args.size == 1
        src = Roll.roll_file
        dst = Roll.construct_roll_file(args[0])
      else
        src = Roll.construct_roll_file(args[0])
        dst = Roll.construct_roll_file(args[1])
      end

      safe_copy(src, dst)

      if opts[:lock]
        Roll.lock(dst)
        puts "Locked '#{dst}`."
      else
        puts "Saved '#{dst}`."
      end
    end

    # Copy a file safely.
    #
    def safe_copy(src, dst)
      if not File.exist?(src)
        $stderr.puts "File does not exist -- '#{src}`"
        exit -1
      end
      if File.exist?(dst) && !opts[:force]
        $stderr.puts "'#{dst}` already exists. Use --force option to overwrite."
        exit -1
      end
      FileUtils.cp(src, dst)
    end
  end

end

