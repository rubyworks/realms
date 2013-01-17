require 'minitest/autorun'

dir = File.dirname(__FILE__)

Dir.entries(dir).each do |spec|
  next unless spec.start_with?('spec_')
  require_relative spec
end

