  source 'http://rubygems.org'

  gem 'rails', '~>3.2.3'
  gem 'builder', '~>3.0.0'

  gem 'blacklight', '~> 4.0.0' 
  gem 'om', '~>1.8.0'
  gem 'hydra-head', '~> 5.0.0'
  gem 'rubydora', '< 1.0.0'

  gem 'hydrant-workflow',
    git: 'https://github.com/variations-on-video/hydrant-workflow.git'
  gem 'hydrant-engage', 
    git: "https://github.com/variations-on-video/hydrant-engage.git"
 
  platforms :jruby do
  	gem 'jruby-openssl'
	gem 'activerecord-jdbcsqlite3-adapter'
	gem 'jdbc-sqlite3'
	gem 'therubyrhino'
  end

  platforms :ruby do
  	gem 'sqlite3'
	gem 'execjs'
     gem 'therubyracer', '= 0.10.2'
  end

  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise'
  #gem 'devise-guests'

  gem "jettywrapper"
  gem 'rubyhorn', :git => "https://github.com/variations-on-video/rubyhorn.git"
  gem 'felixwrapper', :git => "https://github.com/cjcolvar/felixwrapper.git"
  gem 'red5wrapper', :git => "https://github.com/cjcolvar/red5wrapper.git"

  gem 'validates_email_format_of'
  gem 'loofah'
  gem 'omniauth-cas', :git => "https://github.com/cjcolvar/omniauth-cas.git"
  gem 'omniauth-identity'
  gem 'omniauth-ldap'

  gem 'mediainfo'
  gem 'delayed_job_active_record'
  gem 'whenever', :require => false

  gem 'hydrant-batch', :git => "https://github.com/variations-on-video/hydrant-batch.git"

  group :assets, :production do
    gem 'coffee-rails', "~> 3.2.1"
    gem 'uglifier', '>= 1.0.3'
    gem 'jquery-rails'
    gem 'compass-rails', '~> 1.0.0'
    gem 'compass-susy-plugin', '~> 0.9.0', :require => 'susy'

    # For overriding the default interface with Twitter Bootstrap
    # This is now inherited from Blacklight
    #gem 'less-rails'
    #gem 'bootstrap-sass'    
    gem 'sass-rails', '~> 3.2.3'
    gem 'twitter_bootstrap_form_for',
      git: "https://github.com/variations-on-video/twitter_bootstrap_form_for.git",
      branch: "bootstrap-2.0"
  end

  # For testing.  You will probably want to use these to run the tests you write for your hydra head
  group :development, :test do 
    gem 'capistrano', '~>2.12.0'
    gem 'rvm-capistrano'
    gem 'database_cleaner'
    gem 'factory_girl_rails'
    gem 'rspec-rails', '>=2.9.0'
    gem 'pry'
    gem 'pry-rails'
    gem 'unicorn-rails'
    gem 'capistrano-unicorn', :require => false
    gem 'rb-fsevent', '~> 0.9.1'
    gem 'debugger'
  end # (leave this comment here to catch a stray line inserted by blacklight!)

  group :test do
    gem 'mime-types', ">=1.1"
    gem "headless"
    gem "rspec_junit_formatter"
    gem 'simplecov'   
  end
