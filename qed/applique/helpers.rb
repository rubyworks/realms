require 'stringio'

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

