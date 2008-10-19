module Roll

  class Command

    def install
      require 'roll/install'

      opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],

        [ '--git', '-g', GetoptLong::NO_ARGUMENT ],
        [ '--svn', '-s', GetoptLong::NO_ARGUMENT ],

        [ '--uri', '-u', GetoptLong::REQUIRED_ARGUMENT ],

        [ '--tag',      '-t', GetoptLong::REQUIRED_ARGUMENT ],
        [ '--branch',   '-b', GetoptLong::REQUIRED_ARGUMENT ],
        [ '--revision', '-r', GetoptLong::REQUIRED_ARGUMENT ],
        [ '--version',  '-v', GetoptLong::REQUIRED_ARGUMENT ]
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
        when '--tag'
          options[:version_type] = :tag
          options[:version] = arg
        when '--branch'
          options[:version_type] = :branch
          options[:version] = arg
        when '--revision'
          options[:version_type] = :revision
          options[:version] = arg
        when '--version'
          options[:version_type] = :version
          options[:version] = arg
        end
      end

      installer = Roll::Install.new(ARGV[1], options)

      dir = installer.install

      if $PRETEND
      else
        Dir.chdir(dir){ insert }
      end
    end

  end

end

