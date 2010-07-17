require 'stringio'
require 'session'

PWD = Dir.pwd

When 'standard output', 'will look like' do |text|
  out = @stdout.tabto(0).strip  # FIXME: QED is over unindenting the text
  out.assert == text
end

# Override shell operator to internal roll command.
def `(cmd)    #` for highlighter
  case cmd
  #when /^roll\ use/
    # can't run b/c of child shell
  when /^roll/
    cmd = cmd.sub('roll', 'ruby -Ilib bin/roll -')
  end
  stdout, stderr = shell.execute(cmd)
#puts stdout
#puts stderr
  @stdout = stdout
  @stderr = stderr
  raise "#{stderr}" if shell.status != 0
  return @stdout
end

def shell
  @shell ||= (
    sh = ::Session::Bash.new
    sh.execute %[unset RUBYENV]
    sh.execute %[unset roll_environment]
    sh.execute %[export RUBYOPT="-rubygems"]
    sh.execute %[export XDG_CONFIG_HOME="#{PWD}/tmp/config"]
    sh.execute %[export XDG_CACHE_HOME="#{PWD}/tmp/cache"]
    sh
  )
end

=begin
def `(cmd) #`
  case cmd
  when /^roll\ use\ (.*?)$/
    name = $1.strip
    ENV['RUBYENV'] = name
    $LEDGER = Roll::Ledger.new(name)  # pretty crazy, but should be ok for testing
  when /^roll/
    cmd  = cmd.sub('roll', '').strip
    argv = *Shellwords.shellwords(cmd)
    out, err = capture do
      Roll::Command.main(*argv)
    end
    out.rewind; err.rewind
    @stdout, @stderr = out.read, err.read
    return @stdout
  else
    #super(cmd)  # TODO: why did `export` not work?
  end
end

def capture
  out = StringIO.new
  err = StringIO.new
  $stdout = out
  $stderr = err
  yield
  return out, err
ensure
  $stdout = STDOUT
  $stderr = STDERR
end
=end

