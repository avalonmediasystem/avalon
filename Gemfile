  source 'http://rubygems.org'

  gem 'rails', '~>3.2.3'

  gem 'blacklight', '~> 3.3.2'
#  gem 'hydra-head', '~> 4.0.0'
  gem 'hydra-head', :git=>"git://github.com/projecthydra/hydra-head.git"

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

  # Added 
  gem "jettywrapper"
  gem 'rubyhorn', :git => "git://github.com/variations-on-video/rubyhorn.git"
  gem 'felixwrapper', :git => "git://github.com/cjcolvar/felixwrapper.git"
  gem 'red5wrapper', :git => "git://github.com/cjcolvar/red5wrapper.git"

  group :assets, :production do
    gem 'coffee-rails', "~> 3.2.1"
    gem 'uglifier', '>= 1.0.3'
    gem 'jquery-rails'
    gem 'sass-rails', '~> 3.2.3' # moved out of assets to avoid error
    gem 'compass-rails', '~> 1.0.0'
    gem 'compass-susy-plugin', '~> 0.9.0', :require => 'susy'
  end

  # For testing.  You will probably want to use these to run the tests you write for your hydra head
  group :development, :test do 
	gem 'capistrano'
  end # (leave this comment here to catch a stray line inserted by blacklight!)

  group :test do
	gem 'cucumber-rails', '>=1.2.0', :require=>false
        gem 'rspec-rails', '>=2.9.0'
  end
