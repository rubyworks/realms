# 2010-07-18 Version Collapse

As I working with the Rolls code, wrestling it into a precision tool ...

There is a question of how best to deal with library versions. After watching
Mislav's presentation[http://vimeo.com/12615297], I considered the approaches.

RubyGems and the current version of Rolls work essentially the same way.
All versions are available, when you actually active a particular version
or indeirectly do so by requiring a file, then the verison can no longer
change. Attempting to active or require a library of another version will
raise an error. It is a Lazy approach. Nothing happens upfront, only when
the attempt is made is the constraint applied.

Bundler, on the other hand, effects version conflict resolution before any
code is ever run. It does so via a lockdown procedure which resolves the
dependencies and saves them to a special file, which one must load
via a Bunlder interface, in order to gain it's benefit.

Rip pushes the task even further to the forefront, by handling version conflict
at install time, not allowing the installation of two versions of the same
library into the same environment at all. This has a certain simple 
elegance to it, which is admirable. However, it also means managing environments
becomes a fairly involved endeavor --one must personally ensure compatible
environments are setup for each library or application that will be run.

Clearly, there are benefits and deficits to each approach. 

Thinking about Rolls, I wonder if it would be possible to gain the benefits
of upfront version resolution without resorting to lenghthy managment
overhead? Consider what happens when Rolls loads.

    require 'roll'

Roll locates the current environment file and instantiates a reference to
each library version. It stores these in a simple Hash of Arrays in
Leger#index. Inspecting theis index looks something like this:

    {'foo'=>[<Library foo/1.1.0>, <Library foo/1.0.0>], 'bar'=>[<Library bar/1.2>]}

When a library is activated the particular version replaces the subarray, e.g.

    library('foo', '=1.1')

Would reduce the index to:

    {'foo'=><Library foo/1.1.0>, 'bar'=>[<Library bar/1.2>]}

This is how Rolls keeps track of active versions.

What if instead, when +roll+ is loaded, it automatically uses the latest version
of every library in the environment. In most cases that's exactly what we want
anyway. This would simplify the Rolls code a fair bit and make it even
faster --all version resolution woiuld already done by the time our code started
requiring scripts.

But wait... how do we specify versions then? A special file in our library,
can be used to constrain the versions that would be loaded. This file could
either exist in the loadpath or perhaps better in our project metadata.

Guess what? The file already exists. It's the POM REQUIRE file. However, 
I doubt it's a good idea to load that file for each library becuase it requires
YAML to parse and thus it will slow things down. Although it may mean a bit
more management overhead I think it would be better to use the REQUIRE file to
generate a  ruby script that can be put in the lib/ or .ruby/ (or .meta/) path.

There is still one problem with this approach. There remains a lazy component
involved, because we would not know where to start "collapsing the versions"
until the first library is activated --and the first library that has one
of these special files. The issue of libraries not supporting the special
file is actually moot, because in that case they are not versioning anyway
(unless they are using #gem in there library, which would break things
regardless). Nonetheless we still must be able to load files until then.


