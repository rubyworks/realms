require 'rbconfig'

module Roll

  # = Compiler
  #
  class Compiler
    include RbConfig

    class Error < StandardError
    end

    def make(dest_path, results)
      unless File.exist? 'Makefile' then
        raise InstallError, "Makefile not found:\n\n#{results.join "\n"}" 
      end

      mf = File.read('Makefile')
      mf = mf.gsub(/^RUBYARCHDIR\s*=\s*\$[^$]*/, "RUBYARCHDIR = #{dest_path}")
      mf = mf.gsub(/^RUBYLIBDIR\s*=\s*\$[^$]*/, "RUBYLIBDIR = #{dest_path}")

      File.open('Makefile', 'wb') {|f| f.print mf}

      make_program = ENV['make']
      unless make_program then
        make_program = (/mswin/ =~ RUBY_PLATFORM) ? 'nmake' : 'make'
      end

      ['', ' install'].each do |target|
        cmd = "#{make_program}#{target}"
        results << cmd
        results << `#{cmd} #{redirector}`

        raise Error, "make#{target} failed:\n\n#{results}" unless $?.success?
      end
    end

    def redirector
      '2>&1'
    end

    def run(command, results)
      results << command
      results << `#{command} #{redirector}`

      unless $?.success?
        raise Error, "#{self.class} failed:\n\n#{results.join "\n"}"
      end
    end

    # Path to the running Ruby interpreter.
    def ruby
      @ruby ||= (
        ruby = File.join(CONFIG["bindir"], CONFIG["ruby_install_name"])
        ruby << CONFIG["EXEEXT"]
        # escape string if ruby executable path contain spaces
        ruby.sub(/.*\s.*/m, '"\&"')
      )
    end

    #
    def build(extension, directory, dest_path, results)
      case extension
      when /extconf/ then
        build_extconf(extension, directory, dest_path, results)
      when /configure/ then
        build_configure(extension, directory, dest_path, results)
      when /rakefile/i, /mkrf_conf/i then
        ran_rake = true
        build_rake(extension, directory, dest_path, results)
      else
        results = ["No builder for extension '#{extension}'"]
        nil
      end
    end

    #
    def build_configure(extension, directory, dest_path, results)
      unless File.exist?('Makefile') then
        cmd = "sh ./configure --prefix=#{dest_path}"

        run cmd, results
      end

      make dest_path, results

      results
    end

    #
    def build_extconf(extension, directory, dest_path, results)
      cmd = "#{ruby} #{File.basename extension}"
      cmd << " #{ARGV.join ' '}" unless ARGV.empty?

      run cmd, results

      make dest_path, results

      results
    end

    #
    def build_rake(extension, directory, dest_path, results)
      if File.basename(extension) =~ /mkrf_conf/i then
        cmd = "#{ruby} #{File.basename(extension)}"
        cmd << " #{ARGV.join " "}" unless ARGV.empty?
        run cmd, results
      end

      cmd = ENV['rake'] || 'rake'
      cmd += " RUBYARCHDIR=#{dest_path} RUBYLIBDIR=#{dest_path}" # ENV is frozen

      run cmd, results

      results
    end

  end

end

