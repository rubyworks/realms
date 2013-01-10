# 2010-10-07 | A Big Question

A Big Question I had to answer in the development of Rolls was whether
to first allow Ruby to try to require a file, and failing that then let
Rolls at it. This is how RubyGems works. Early on Rollls did the same,
but it soon became appearent that there were some issues with this approach.

First it mean awating an error rescue, which is rather slow. Right off
the bat we're taking a speed hit.

Secondly, the question of priority arises. Should Ruby's file take priority,
or should they be overridable. A good example is RDoc. The verison
distributed with Ruby is quite old. Certainly a later version should take
precedence. The order of Ruby's own $LOAD_PATH indicates this, since site
locations Ruby's install location.

Lastly with Ruby 1.9 automatical inclusion of of Gem locations, letting
Ruby try first means letting RubyGems go gfirst too --and that simply
can never work.

For these reasons, it became clear the Rolls needs to do it's thing first
and then fallback to Ruby. However, there is also an problem with this
approach --it is not efficient. Consider how foolish it is to search
through the entire "roll" of libraries for a standard Ruby library
like 'ostruct.rb'. It maks no sense.

What we will need to do to resolve the issue satisfactorily it separate
the standard lib into "truly standard lib" vs. "3rd party standard lib".
we can allow the former to load first, but keep the later for last.
I am not 100% sure how to program Rolls to make the distiction yet,
but there should be some means --and it is cleary the best course.
