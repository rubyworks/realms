module Roll

  class Command

    #
    def path_optparse(opts, options)
      opts.banner = "Usage: roll path"
      opts.separator "Generate executable PATH list."
      return opts
    end

    # This script builds a list of all roll-ready bin locations
    # and writes that list as an environment setting shell script.
    # On Linux a call to this to you .bashrc file. Eg.
    #
    #   if [ -f ~/.rollrc ]; then
    #       . roll
    #   fi
    #
    # Currently this only supports bash.
    #
    # TODO: It would be better to "install" executables
    # to an appropriate bin dir, using links (soft if possible).
    # There could go in ~/.bin or .config/roll/<ledger>.bin/
    #
    def path(args, options)
      div = (windows? ? ';' : ':')

      env_path = ENV['PATH'].split(/[#{div}]/)

      # Go thru each roll lib and make sure bin
      # path in path.
      binpaths = []
      Library.list.each do |libname|
        path = Library[libname].bindir
        binpaths << path if path
      end

      #pathenv = (["$PATH"] + binpaths).join(div)

      pathenv = binpaths.join(div)

      #puts %{export PATH="#{pathenv}"}

      puts pathenv
    end

  end

end

