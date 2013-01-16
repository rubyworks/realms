module Realms
  class Library
    module Shell
      register :path

      # Build a list of all library bin locations and writes that list as a
      # environment setting shell script. On Linux, add a call to this in your
      # .bashrc file, e.g.
      #
      #     export PATH="$(realm path):$PATH"
      #
      # Or better, put this in a `.config/bashrc/ruby.sh` file. And then 
      # in your `.bashrc file:
      #
      #     if [ -f ~/.config/bashrc/ruby.sh ]; then
      #         source ~/.config/bashrc/ruby.sh
      #     fi
      #
      def path
        op.banner = "Usage: realm path"
        op.separator "Generate list of executable paths usable in PATH environment variable."

        parse

        $stdout.puts $LOAD_MANAGER::PATH()
      end

    end
  end
end
