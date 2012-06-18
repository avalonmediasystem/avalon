  source 'http://rubygems.org'

  gem 'rails', '~>3.2.3'

  gem 'blacklight', '~> 3.4.1'
  gem 'hydra-head', '~> 4.0.0'
  #gem 'hydra-head', :git=>"git://github.com/projecthydra/hydra-head.git"

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

  # We will assume you're using devise in tutorials/documentation. 
  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise'

	# Needed for AJAX file upload
	#gem 'remotipart'
        gem 'jquery-fileupload-rails', '>= 0.3'

  # Added 
  gem "jettywrapper"
  gem 'rubyhorn', :git => "git://github.com/variations-on-video/rubyhorn.git"
#  gem 'rubyhorn'
  gem 'felixwrapper', :git => "git://github.com/cjcolvar/felixwrapper.git"
  gem 'red5wrapper', :git => "git://github.com/cjcolvar/red5wrapper.git"

  group :assets, :production do
    gem 'coffee-rails', "~> 3.2.1"
    gem 'uglifier', '>= 1.0.3'
    gem 'jquery-rails'
    gem 'compass-rails', '~> 1.0.0'
    gem 'compass-susy-plugin', '~> 0.9.0', :require => 'susy'
    
    # For overriding the default interface with Twitter Bootstrap
    gem 'sass-rails', '~> 3.2.3'
    gem 'twitter-bootstrap-rails', "~> 2.0"
    gem 'twitter_bootstrap_form_for', "~> 1.0"
    gem 'bootstrap-will_paginate'
  end

  # For testing.  You will probably want to use these to run the tests you write for your hydra head
  group :development, :test do 
	gem 'capistrano'
	gem 'rvm-capistrano'
	gem 'database_cleaner'
  end # (leave this comment here to catch a stray line inserted by blacklight!)

  group :test do
	gem 'cucumber-rails', '>=1.2.0', :require=>false
    gem 'rspec-rails', '>=2.9.0'
    gem 'capybara-webkit'
    gem 'capybara-screenshot'
    gem 'mime-types', ">=1.1"
    gem "headless"
  end
