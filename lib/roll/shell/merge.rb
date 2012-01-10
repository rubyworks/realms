module Roll

  module Shell

    #
    # Merge one roll with another.
    #
    def merge
      op.banner = "Usage: roll merge [from]\n" +
                  "       roll merge [from] [to]" 
      op.separator "Merge roll files."
      op.on('--lock', '-l', "Lock after merging.") do
        opts[:lock] = true
      end

      parse

      if argv.size == 1
        src = Roll.roll_file
        dst = Roll.construct_roll_file(args[0])
      else
        src = Roll.construct_roll_file(args[0])
        dst = Roll.construct_roll_file(args[1])
      end

      safe_merge(src, dst)

      if opts[:lock]
        Roll.lock(dst)
        puts "Locked '#{dst}`."
      else
        puts "Saved '#{dst}`."
      end
    end

  private

    # Merge files safely.
    #
    def safe_merge(src, dst)
      if not File.exist?(src)
        $stderr.puts "File does not exist -- '#{src}`"
        exit -1
      end

      if not File.exist?(dst)
        $stderr.puts "'#{dst}` already exists. Use --force option to overwrite."
        exit -1
      end

      src_txt = File.read(src).strip
      dst_txt = File.read(src).strip

      File.open(dst, 'w') do |file|
        file << dst_txt + "\n" + src_txt
      end
    end

  end

end

