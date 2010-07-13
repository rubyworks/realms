module Roll

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
  class CommandPath < Command

    #
    def setup
      op.banner = "Usage: roll path"
      op.separator "Generate executable PATH list."
    end

    #
    def call
      case RUBY_PLATFORM
      when /mswin/, /wince/
        div = ';'
      else
        div = ':'
      end
      env_path = ENV['PATH'].split(/[#{div}]/)
      # Go thru each roll lib and make sure bin path is in path.
      binpaths = []
      Library.list.each do |name|
        lib = Library[name]
p lib
        if lib.bindir?
          binpaths << lib.bindir
        end
      end
      #pathenv = (["$PATH"] + binpaths).join(div)
      pathenv = binpaths.join(div)
      #puts %{export PATH="#{pathenv}"}
      puts pathenv
    end

  end

end
