class Realms::Library

  module Shell

    # TODO: Would it be better to "install" executables
    # to an appropriate bin dir, using links (soft if possible).
    # There could go in ~/.bin or .config/roll/<ledger>.bin/

    # This script builds a list of all roll-ready bin locations
    # and writes that list as an environment setting shell script.
    # On Linux, add a call to this in your .bashrc file, e.g.
    #
    #   export PATH="$(roll path):$PATH"
    #
    # Or better, put this in a `.config/bashrc/ruby.sh` file. And then 
    # in your `.bashrc file:
    #
    #   if [ -f ~/.config/bashrc/ruby.sh ]; then
    #       . ~/.config/bashrc/ruby.sh
    #   fi
    #
    # Currently this only supports bash.
    #
    def path
      op.banner = "Usage: roll path"
      op.separator "Generate executable PATH list."

      parse

      case RUBY_PLATFORM
      when /mswin/, /wince/
        div = ';'
      else
        div = ':'
      end

      env_path = ENV['PATH'].split(/[#{div}]/)

      # go thru each roll lib and make sure bin path is in path
      binpaths = []
      Library.list.each do |name|
        lib = Library[name]
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
