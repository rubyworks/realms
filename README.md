[Homepage](http://rubyworks.github.com/realms) /
[Documentation](http://wiki.github.com/rubyworks/realms) /
[Report Issue](http://github.com/rubyworks/realms/issues) /
[Source Code](http://github.com/rubyworks/realms)
( )


# REALMS

```
          <|
           A
          /.\
     <|  [""M#
      A   | #              Realms
     /.\ [""M#
    [""M# | #  U"U#U
     | #  | #  \ .:/
     | #  | #___| #
     | "--'     .-"
   |"-"-"-"-"-#-#-##
   |     # ## ######
    \       .::::'/
     \      ::::'/
   :8a|    # # ##
   ::88a      ###
  ::::888a  8a ##::.
  ::::::888a88a[]::::
 :::::::::SUNDOGa8a::::. ..
 :::::8::::888:Y8888:::::::::...
::':::88::::888::Y88a______________________________________________________
:: ::::88a::::88a:Y88a                                  __---__-- __
' .: ::Y88a:::::8a:Y88a                            __----_-- -------_-__
  :' ::::8P::::::::::88aa.                   _ _- --  --_ --- __  --- __--
.::  :::::::::::::::::::Y88as88a...s88aa.
```

REALMS is a library management system for Ruby. In fact, the name is
an anacronym which stands for *Ruby Enhanced Library Management System*.
Okay, it sounds neat, but what does Realms actually do?

Realms core functionality is to take a list of file system locations, sift
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


## Limitations

Ruby has a "bug" which prevents `#autoload` from using custom `#require`
methods. So autoload paths cannot make use of Realms. However, Realms
has a fallback system which allows autoload to work so long as the path
lies within the current library. It is only a show-stopper when autoload
is used to load scripts from outside dependencies. This is not as significant
as it might seem for two reasons. 1) Most uses of autoload are interal;
and 2) autoload is in the process of being deprecated as of Ruby 2.0. So
it is best to discontinue it's use anyway.


## Documentation

Because there is fair amount of information to cover this section will
refer you to the project wiki pages for instruction. Most users can follow
the [Quick Start Guide](https://github.com/rubyworks/realms/wiki/Quick-Start-Guide).
For more detailed instruction on how setup Realms and get the most out select
from the following links:

* [Installation](https://github.com/rubyworks/realms/wiki/Installation)
* [System Setup](https://github.com/rubyworks/realms/wiki/System-Setup)
* [Project Conformity](https://github.com/rubyworks/library/wiki/Project-Conformity)
* [Run Modes](https://github.com/rubyworks/realms/wiki/Run-Modes)
* [Dependency Isolation](https://github.com/rubyworks/realms/wiki/Dependency-Isolation)
* [Configuring Locations](https://github.com/realms/library/wiki/Configuring-Locations)
* [API Usage](https://github.com/rubyworks/realms/wiki/API-Usage)


## FAQ

Realms was originally called Roll and was RubyForge project #1004.
She's actually been around a while! :)


## Copyrights

Realms is copyrighted open source software.

    Copyright (c) 2006 Rubyworks

It can be modified and redistributable in accordance with the **BSD-2-Clause** license.

See the LICENSE.txt file details.
