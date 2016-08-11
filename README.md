# Avalon 6 Development Branch

[![Build Status](https://travis-ci.org/avalonmediasystem/avalon.svg?branch=hydra10-fresh)](https://travis-ci.org/avalonmediasystem/avalon)

# Installing Avalon 6 For Devs

* create a new directory to clone a free copy of Avalon into
* switch to Ruby 2.3.1 ``rvm install 2.3.1`` and ``rvm use 2.3.1`` (``rvm --default use 2.3.1`` will also make 2.3.1 your new default)
* ``bundle install``
* ``cp config/authentication.yml.example config/authentication.yml``
* ``rake db:migrate``
* ``bundle install``
* ``bundle exec rake server:development`` or ``bundle exec rake server:test`` Note: This process will not background itself, it will occupy the terminal you run it in

# Nokogiri Problems on OS X

Oddly enough despite having no problems with Nokogiri when using Ruby 2.2, switching 2.3.1 caused me to no longer be able to install it.  I had to run:

* ``xcode-select --install`` and then complete the GUI install menu that pops up
* ``bundle config build.nokogiri --use-system-libraries --with-xml2-include=/usr/include/libxml2``

With that everything went back to working.
