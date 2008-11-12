module Roll

  WIN_PATTERNS = [
    /bccwin/i,
    /cygwin/i,
    /djgpp/i,
    /mingw/i,
    /mswin/i,
    /wince/i,
  ]

  # Is this a windows platform?
  def self.win_platform?
    @win_platform ||= (
      !!WIN_PATTERNS.find{ |r| RUBY_PLATFORM =~ r }
    )
  end

end

