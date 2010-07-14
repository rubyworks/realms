module Roll

  #
  class CommandDotruby < Command

    #
    def setup
      op.banner = "Usage: roll .ruby [NAME]"
      op.separator "Automatically add .ruby entries to lookup locations."
    end

    # Synchronize ledgers.
    #
    def call
      name = args.first
      case name
      when 'nil'
        list = [Environment.current]
      when 'all'
        list = Environment.list
      else
        list = [name]
      end

      list.each do |name|
        result = Roll::Library.prep(name)
        #if result
        #  puts "Added .ruby entries for `#{name}`."
        #else
        #  puts "Index for `#{name}` is already current."
        #end
      end
    end

  end

end
