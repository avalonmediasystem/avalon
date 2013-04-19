  source 'http://rubygems.org'

  gem 'rails', '~>3.2.3'
  gem 'builder', '~>3.0.0'

  gem 'blacklight', '~> 4.0.0' 
  gem 'om', '~>1.8.0'
  gem 'hydra-head', '~> 5.0.0'
  gem 'rubydora', '< 1.0.0'
  gem 'active-fedora', '~> 5.0.0'

  gem 'avalon-workflow', git: 'https://github.com/avalonmediasystem/avalon-workflow.git'
  gem 'avalon-engage', git: "https://github.com/avalonmediasystem/avalon-engage.git"
  gem 'avalon-batch', git: "https://github.com/avalonmediasystem/avalon-batch.git"
 
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
  gem 'haml'

  gem "jettywrapper"
  gem 'rubyhorn', :git => "https://github.com/avalonmediasystem/rubyhorn.git"
  gem 'felixwrapper', :git => "https://github.com/avalonmediasystem/felixwrapper.git"
  gem 'red5wrapper', :git => "https://github.com/avalonmediasystem/red5wrapper.git"

  gem 'validates_email_format_of'
  gem 'loofah'
  gem 'omniauth-identity'

  gem 'mediainfo'
  gem 'delayed_job_active_record'
  gem 'whenever', :require => false

  gem 'equivalent-xml'
  
  group :assets, :production do
    gem 'coffee-rails', "~> 3.2.1"
    gem 'uglifier', '>= 1.0.3'
    gem 'jquery-rails', "~> 2.1.4"
    gem 'compass-rails', '~> 1.0.0'
    gem 'compass-susy-plugin', '~> 0.9.0', :require => 'susy'

    # For overriding the default interface with Twitter Bootstrap
    # This is now inherited from Blacklight
    gem 'sass-rails', '~> 3.2.3'
    gem 'font-awesome-sass-rails'
    gem 'twitter_bootstrap_form_for',
      git: "https://github.com/avalonmediasystem/twitter_bootstrap_form_for.git",
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
    #gem 'capistrano-unicorn', :require => false
    gem 'capistrano-unicorn',
      git: "git://github.com/sosedoff/capistrano-unicorn.git"
    gem 'rb-fsevent', '~> 0.9.1'
    gem 'debugger'
    gem 'letter_opener'
    gem 'grit'
    gem 'license_header'
  end # (leave this comment here to catch a stray line inserted by blacklight!)

  group :test do
    gem 'mime-types', ">=1.1"
    gem "headless"
    gem "rspec_junit_formatter"
    gem 'simplecov'
    gem 'email_spec'
    gem 'capybara'   
  end

  extra_gems = File.expand_path("../Gemfile.local",__FILE__)
  eval File.read(extra_gems) if File.exists?(extra_gems)
