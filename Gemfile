  source 'http://rubygems.org'

  gem 'rails', '~>3.2.3'

  gem 'blacklight', '~> 3.3.2'
#  gem 'hydra-head', '~> 4.0.0'
  gem 'hydra-head', :git=>"git://github.com/projecthydra/hydra-head.git"

  # We will assume that you're using sqlite3 for testing/demo, 
  # but in a production setup you probably want to use a real sql database like mysql or postgres
  gem 'sqlite3'

  # We will assume you're using devise in tutorials/documentation. 
  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise'

  # For testing.  You will probably want to use these to run the tests you write for your hydra head
  group :development, :test do 
         gem 'jquery-rails'
         gem 'rspec-rails', '>=2.9.0'
         gem "jettywrapper"

         # Added 
         gem 'rubyhorn', :git => "git://github.com/variations-on-video/rubyhorn.git"
         gem 'felixwrapper', :git => "git://github.com/cjcolvar/felixwrapper.git"
         gem 'red5wrapper', :git => "git://github.com/cjcolvar/red5wrapper.git"

  end # (leave this comment here to catch a stray line inserted by blacklight!)
