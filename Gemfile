  source 'http://rubygems.org'

  gem 'rails', '~>3.2.3'

  gem 'blacklight', '~> 3.3.2'
  gem 'hydra-head', '~> 4.0.0'
#  gem 'hydra-head', :git=>"git://github.com/projecthydra/hydra-head.git"

  # We will assume that you're using sqlite3 for testing/demo, 
  # but in a production setup you probably want to use a real sql database like mysql or postgres
  gem 'sqlite3'

  # We will assume you're using devise in tutorials/documentation. 
  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise'

  group :assets do
    gem 'coffee-rails', "~> 3.2.1"
    gem 'uglifier', '>= 1.0.3'
    gem 'compass-rails', '~> 1.0.0'
    gem 'compass-susy-plugin', '~> 0.9.0', :require => 'susy'
  end

  # For testing.  You will probably want to use these to run the tests you write for your hydra head
  group :development, :test do 
         gem 'sass-rails', '~> 3.2.3'
         gem 'jquery-rails'
         gem 'rspec-rails', '>=2.9.0'
         gem "jettywrapper"

         # Added 
         gem 'rubyhorn', :git => "git://github.com/variations-on-video/rubyhorn.git", :branch=>"HH4"
         gem 'felixwrapper', :git => "git://github.com/cjcolvar/felixwrapper.git", :branch=>"HH4"
         gem 'red5wrapper', :git => "git://github.com/cjcolvar/red5wrapper.git", :branch=>"HH4"

  end # (leave this comment here to catch a stray line inserted by blacklight!)
