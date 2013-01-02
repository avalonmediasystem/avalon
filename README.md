# Avalon Media System
[Something about the purpose of the project]

For more information visit http://wiki.dlib.indiana.edu/display/VarVideo

# Installing Avalon Media System
Instructions on how to get a local installation of Avalon Media System installed on your system are available for [Linux](https://wiki.dlib.indiana.edu/display/VarVideo/Getting+Started+-+Linux) and [OS X](https://wiki.dlib.indiana.edu/display/VarVideo/Getting+Started+-+Mac).
# Getting started:

* ```git submodule init```
* ```git submodule update```
* Install Mediainfo cli: http://mediainfo.sourceforge.net
* Copy config/hydrant.yml.example to config/hydrant.yml and change as necessary
* ```rake db:migrate```
* ```rake jetty:start```
* ```rake felix:start```
* ```rake spec```

# For batch ingest:
* rake hydrant:batch:ingest