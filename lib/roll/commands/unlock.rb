module Roll

  # 
  #++
  # TODO: Ultimately allow for caching a different groups?
  #--
  class CommandUnlock < Command
    #
    def setup
      op.banner = "Usage: roll clear"
      op.separator "Clear current ledger cache."
    end

    #
    def call
      file = Roll.unclock
      $stdout.puts "Unlocked `#{file}'."
    end
  end

end
