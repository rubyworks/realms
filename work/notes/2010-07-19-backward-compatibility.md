# 2010-07-19 Backward Compatibility

A difficuly of designing an alternate load system for Ruby is backward
compatibilty. Rolls offers a legacy mode to help in this regard. It
can be invoked as follows:

    require('foo', :legacy=>true}

So this will require 'foo' in the old fashion manner of searching through
all the libraries for a matching file and loading the first one it finds.

But a problem arises for systems not using Rolls. This will raise an error
b/c #require does not normally take an options hash. Thankfully there is a
workaround. Rather than pass an options hash directly, we pass it via a block.

    require('foo'){{:legacy=>true}}

Ruby ignores extraneous blocks. So this will work with or without Rolls.
