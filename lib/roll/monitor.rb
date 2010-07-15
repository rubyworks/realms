require 'roll/original'

module ::Kernel

  # Require script.
  def require(file)
    $stderr.puts "require: #{file}"
    roll_original_require(file)
  end

  module_function :require

  # Load script.
  def load(file, wrap=false)
    $stderr.puts "load: #{file}"
    roll_original_load(file, wrap)
  end

  module_function :load

end
