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
* Create config overwrites in [``config/settings/development.local.yml``](https://wiki.dlib.indiana.edu/display/VarVideo/Configuration+Files#ConfigurationFiles-config/settings.yml) if necessary
* ```cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml```
* Install [cmake](https://cmake.org/) if necessary.  This can typically be installed via package manager
* ```bundle install```
* ```rake secret```
* ```rake avalon:services:start```
* ```rake avalon:db_migrate```
* ```rake db:test:prepare```
* ``bundle exec rake server:development`` or ``bundle exec rake server:test`` Note: This process will not background itself, it will occupy the terminal you run it in

# Quickstart development with Docker
Docker provides an alternative way of setting up an Avalon Media System Development Environment in minutes without installing any dependencies beside Docker itself. It should be noted that the docker-compose.yml provided here is for development only and will be updated continually.
* Install [Docker](https://docs.docker.com/engine/installation/) and [docker-compose](https://docs.docker.com/compose/install/)
* ```git clone https://github.com/avalonmediasystem/avalon```
* ```cd avalon```
* ```cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml```
* ```docker-compose up```
* Try loading Avalon in your browser: ```localhost:3000```

Avalon is served by Webrick in development mode so any changes will be picked up automatically. Running a Rails command inside the Avalon container is easy, for example, to run tests ```docker-compose exec avalon bash -c "RAILS_ENV=test bundle exec rspec"```. Note: to avoid erasing development data, you should use the test stack to run tests```docker-compose -f test.yml up```.

Rails debugging with Pry can be accessed by attaching to the docker container: ```docker attach container_name```. Now, when you reach a binding.pry breakpoint in rails, you can step through the breakpoint in that newly attached session.

# Javascript style checking and code formatting
### ESLint - Style checking
In order to run eslint on javascript files to check prior to creating a pull request do the following:
1. Install eslint globally, locally on dev machine: `npm install -g eslint`
2. Run `eslint app/assets/javascripts/ --ext .js,.es6`

### Prettier - Code formatting
To maintain a consistent style of .js/.es6 code, the Prettier package should be used to clean up code before submitting a pull request.
1. Install Prettier globally, locally on dev machine: (https://prettier.io/) `yarn global add prettier` or `npm install --global prettier`
2. (optional) To be safe, you may want to commit your code before running through Prettier.
3. Run the `prettier` CLI command from the application root directory, for example: `prettier --write "app/assets/javascripts/media_player_wrapper/*.es6"`
3. Commit your re-formatted, beautiful code.

# Browser Testing
Testing support for Avalon Media System is provided by [BrowserStack](https://www.browserstack.com).
