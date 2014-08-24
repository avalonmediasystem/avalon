# Avalon Media System
[Avalon Media System](http://www.avalonmediasystem.org) is an open source system for managing large collections of digital audio and video. The project is led by the libraries of [Indiana University](http://www.iu.edu) and [Northwestern University](http://www.northwestern.edu) with funding in part by a three-year National Leadership Grant from the [Institute of Museum and Library Services](http://www.imls.gov).

For more information and regular project updates visit the [Avalon blog](http://www.avalonmediasystem.org/blog).

# Installing Avalon Media System
Instructions on how to get a local installation of Avalon Media System installed on your system are available for [Linux](https://wiki.dlib.indiana.edu/display/VarVideo/Getting+Started+\(Linux\)) and [OS X](https://wiki.dlib.indiana.edu/display/VarVideo/Getting+Started+\(OS+X\)).

# Getting started

1. Clone the repository if you haven't yet:
```git clone --recursive https://github.com/avalonmediasystem/avalon```
2. Create ```avalon.yml``` and ```authentication.yml``` using the examples in the config directory.
3. Install [Mediainfo](http://mediainfo.sourceforge.net).
4. Install [Matterhorn](https://wiki.dlib.indiana.edu/display/VarVideo/Getting+Started+(OS+X)#GettingStarted%28OSX%29-InstallMatterhorndependencies).
4. Start Avalon services:
```bundle && rake avalon:services:start```
5. Prepare the development and test databases:
```rake db:migrate && rake db:test:prepare``
6. Run the tests (optional):
```rspec spec```
7. Start the server:
```rails s```