# Avalon Media System
[Avalon Media System](http://www.avalonmediasystem.org) is an open source system for managing large collections of digital audio and video. The project is led by the libraries of [Indiana University](http://www.iu.edu) and [Northwestern University](http://www.northwestern.edu) with funding in part by a three-year National Leadership Grant from the [Institute of Museum and Library Services](http://www.imls.gov).

[![Build Status](https://travis-ci.org/avalonmediasystem/avalon.svg?branch=develop)](https://travis-ci.org/avalonmediasystem/avalon)

[![Stories in Ready](https://badge.waffle.io/avalonmediasystem/avalon.png?label=ready&title=Ready)](https://waffle.io/avalonmediasystem/avalon)

[![Coverage Status](https://coveralls.io/repos/avalonmediasystem/avalon/badge.svg?branch=master&service=github)](https://coveralls.io/github/avalonmediasystem/avalon?branch=master)

For more information and regular project updates visit the [Avalon blog](http://www.avalonmediasystem.org/blog).

# Move to Fedora 4

Please note that effective 14 March 2017, our master branch now tracks our Fedora 4 based Avalon.  For our old Fedora 3 based product (Avalon 5.x and earlier) please use the `5.x-stable` branch.  Enhancements for Avalon 5.x can be submitted to the `5.x-dev` branch.

# Installing Avalon Media System
Instructions on how to get a local installation of Avalon Media System installed on your system are available for [Linux](https://wiki.dlib.indiana.edu/display/VarVideo/Getting+Started+(Linux)) and [OS X](https://wiki.dlib.indiana.edu/display/VarVideo/Getting+Started+(OS+X)).

# Setting Up an Avalon Media System Development Environment
For developers using OS X, you can get a full Avalon development environment, including transcoding and streaming using docker.  [See the wiki](https://github.com/avalonmediasystem/avalon/wiki/Configuring-an-OS-X-Development-Environment-With-Docker-Containers) for details, this is currently our recommended way to setup a dev environment.  

The following steps will let you run the avalon stack locally in order to
explore the out-of-the-box functionality or do basic development.

* Ensure that you're running one of the Ruby versions listed in under rvm in ".travis.yml".
* Install [Mediainfo cli](http://mediainfo.sourceforge.net)
* Copy config/avalon.yml.example to config/avalon.yml and [change](https://wiki.dlib.indiana.edu/display/VarVideo/Configuration+Files#ConfigurationFiles-config%2Favalon.yml) as necessary
* ```cp config/authentication.yml.example config/authentication.yml```
* ```cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml```
* Install [cmake](https://cmake.org/) if necessary.  This can typically be installed via package manager
* ```bundle install```
* ```rake secret```
* ```rake avalon:services:start```
* ```rake avalon:db_migrate```
* ```rake db:test:prepare```
* ``bundle exec rake server:development`` or ``bundle exec rake server:test`` Note: This process will not background itself, it will occupy the terminal you run it in


# Browser Testing
Testing support for Avalon Media System is provided by [BrowserStack](https://www.browserstack.com).
