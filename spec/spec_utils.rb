require_relative 'helper'

describe Realms::Library::Utils do

  it "should get lookup paths from RUBY_LIBRARY environment if set" do
    lib_paths = Library::Utils.lookup_paths
    env_paths = ENV['RUBY_LIBRARY'].split(/[:;]/)
    assert lib_paths = env_paths
  end

end
