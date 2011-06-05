class File

  #
  RE_PATH_SEPERATOR = Regexp.new('[' + Regexp.escape(File::Separator + %q{\\\/}) + ']')

  #
  def self.split_root(path)
    path.split(RE_PATH_SEPERATOR, 2)
  end

end
