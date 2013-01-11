module Rolls

  #
  # Access to project metadata via constant names.
  #
  # @example
  #   Rolls::VERSION  #=> "2.0.0"
  #
  def self.const_missing(name)
    index[name.to_s.downcase] || super(name)
  end

  #
  # Access to project metadata.
  #
  def self.index
    @index ||= (
      require 'yaml'
      file = File.expand_path('../rolls.yml', File.dirname(__FILE__))
      YAML.load_file(file)
    )
  end

end
