(class << $LOAD_PATH; self; end).class_eval do
  alias_method :require, :require
  alias_method :load, :load
end

