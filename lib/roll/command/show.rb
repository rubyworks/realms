module Roll

  class Command

    # Show project versions (branches/tags).
    def show
      require 'roll/install'

      opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],

        [ '--git', '-g', GetoptLong::NO_ARGUMENT ],
        [ '--svn', '-s', GetoptLong::NO_ARGUMENT ],

        [ '--uri', '-u', GetoptLong::REQUIRED_ARGUMENT ]
      )

      options = {}

      opts.each do |opt, arg|
        case opt
        when '--help'
          # TODO
        when '--git'
          options[:scm_type] = :git
        when '--svn'
          options[:scm_type] = :svn
        end
      end

      installer = Roll::Install.new(ARGV[1], options)
      installer.show
    end

  end

end

