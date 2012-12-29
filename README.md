[Homepage](http://rubyworks.github.com/rolls) /
[Documentation](http://wiki.github.com/rubyworks/rolls) /
[Report Issue](http://github.com/rubyworks/rolls/issues) /
[Source Code](http://github.com/rubyworks/rolls)
( )


# RUBY ROLLS

<pre style="color:red">
                  ____
              ,dP9CGG88@b,
            ,IP""YICCG888@@b,
           dIi   ,IICGG8888@b
          dCIIiciIICCGG8888@@b
  ________GCCIIIICCCGGG8888@@@________________
          GGCCCCCCCGGG88888@@@
          GGGGCCCGGGG88888@@@@...
          Y8GGGGGG8888888@@@@P.....
           Y88888888888@@@@@P......
           `Y8888888@@@@@@@P'......
              `@@@@@@@@@P'.......
                  """"........
</pre>


ROLLS is a library management system for Ruby. In fact, the name is
an anacronym which stands for *Ruby Objectified Library Ledger System*.

Okay, it sounds neat, but what does Rolls actually do?

Rolls' core functionality is to take a list of file system locations, sift
through them to find Ruby projects and make them available via Ruby's `require`
and `load` methods. It does this in such a way that is *customizable* and *fast*.

Along with some supporting functionality, this bestows a variety of useful
possibilities to Ruby developers:

* Work with libraries in an object-oriented manner.
* Develop interdependent projects in real time without installs or vendoring. 
* Create isolated library environments based on project requirements.
* Nullify the need for per-project gemsets and multiple copies of the same gem.
* Access libraries anywhere; there is no special "home" path they *must* reside.
* Serve gem installed libraries faster than RubyGems itself.


## Status

Rolls works fairly well. The core system has been in use for years.
So, on the whole, the underlying functionality is in good working order.
But the system is still undergoing development, in particular, work
on simplifying configuration and management, so some things are still
subject to change.


## Limitations

Ruby has a "bug" which prevents `#autoload` from using custom `#require`
methods. So `#autoload` calls cannot make use of Rolls.  This is not as
significant as it might seem since `#autoload` is being deprecated as
of Ruby 2.0. So it is best to discontinue it's use anyway.


## Documentation

Because there is fair amount of information to cover this section will
refer you to the project wiki pages for instruction. Most users can follow
the [Quick Start Guide](https://github.com/rubyworks/rolls/wiki/Quick-Start-Guide).
For more detailed instruction on how setup Rolls and get the most out select
from the following links:

* [Installation](https://github.com/rubyworks/rolls/wiki/Installation)
* [System Setup](https://github.com/rubyworks/rolls/wiki/System-Setup)
* [Project Conformity](https://github.com/rubyworks/library/wiki/Project-Conformity)
* [Run Modes](https://github.com/rubyworks/rolls/wiki/Run-Modes)
* [Dependency Isolation](https://github.com/rubyworks/rolls/wiki/Dependency-Isolation)
* [Configuring Locations](https://github.com/rolls/library/wiki/Configuring-Locations)
* [API Usage](https://github.com/rubyworks/rolls/wiki/API-Usage)


## FAQ

Rolls was RubyForge project #1004. She's been around a while! :)


## Copyrights

Rolls is copyrighted open source software.

    Copyright (c) 2006 Rubyworks

It can be modified and redistributable in accordance with the **BSD-2-Clause** license.

See the LICENSE.txt file details.
