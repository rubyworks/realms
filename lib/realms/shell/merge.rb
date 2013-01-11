module Realms

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
        src = Realms.roll_file
        dst = Realms.construct_roll_file(argv[0])
      else
        src = Realms.construct_roll_file(argv[0])
        dst = Realms.construct_roll_file(argv[1])
      end

      safe_merge(src, dst)

      if opts[:lock]
        Roll.lock(dst)
        puts "Saved & Locked: #{dst}"
      else
        puts "Saved: #{dst}"
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

