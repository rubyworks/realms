module Roll

  class Command

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
    # TODO: Is this the best way to do it, or would it be better
    # to "install" executables to an appropriate bin dir,
    # suing links (soft if possible).
    #
    def path
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

