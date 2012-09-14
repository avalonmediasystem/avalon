  source 'http://rubygems.org'

  gem 'rails', '~>3.2.3'
  gem 'builder', '~>3.0.0'

  gem 'blacklight', '~> 3.4'
  gem 'hydra-head', '~> 4.1.0'
  gem 'hydrant-engage', :git=>"git://github.com/variations-on-video/hydrant-engage.git"
  gem 'active-fedora', '~> 4.2'

  platforms :jruby do
  	gem 'jruby-openssl'
	gem 'activerecord-jdbcsqlite3-adapter'
	gem 'jdbc-sqlite3'
	gem 'therubyrhino'
  end

  platforms :ruby do
  	gem 'sqlite3'
	gem 'execjs'
    gem 'therubyracer'
  end

  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise'

  gem "jettywrapper"
  gem 'rubyhorn', :git => "git://github.com/variations-on-video/rubyhorn.git"
  gem 'felixwrapper', :git => "git://github.com/cjcolvar/felixwrapper.git"
  gem 'red5wrapper', :git => "git://github.com/cjcolvar/red5wrapper.git"

  gem 'validates_email_format_of'
  gem 'loofah'
  gem 'devise_cas_authenticatable', :git => "git://github.com/cjcolvar/devise_cas_authenticatable.git"
  gem 'rubycas-client', :git => "git://github.com/cjcolvar/rubycas-client.git"    

  group :assets, :production do
    gem 'coffee-rails', "~> 3.2.1"
    gem 'uglifier', '>= 1.0.3'
    gem 'jquery-rails'
    gem 'compass-rails', '~> 1.0.0'
    gem 'compass-susy-plugin', '~> 0.9.0', :require => 'susy'

    # For overriding the default interface with Twitter Bootstrap
    gem 'sass-rails', '~> 3.2.3'
    gem 'twitter-bootstrap-rails', "~> 2.0"
    gem 'twitter_bootstrap_form_for',
      git: "git://github.com/variations-on-video/twitter_bootstrap_form_for.git",
      branch: "bootstrap-2.0"
    gem 'bootstrap-will_paginate'
  end

  # For testing.  You will probably want to use these to run the tests you write for your hydra head
  group :development, :test do 
	gem 'capistrano', '~>2.12.0'
	gem 'rvm-capistrano'
	gem 'database_cleaner'
	gem 'factory_girl_rails'
    gem 'rspec-rails', '>=2.9.0'
    # For debugging as a richer replacement for irb
    #
    # To use enter
    # pry -r ./config/environment.rb at the command line
    gem 'pry'
  end # (leave this comment here to catch a stray line inserted by blacklight!)

  group :test do
    gem 'cucumber-rails', '>=1.2.0', :require=>false
    gem 'capybara-webkit'
    gem 'capybara-screenshot'
    gem 'mime-types', ">=1.1"
    gem "headless"
    gem "rspec_junit_formatter"
    gem 'simplecov'
    
    gem 'viewcumber'
  end
