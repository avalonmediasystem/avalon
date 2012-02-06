  source 'http://rubygems.org'

  gem 'rails', '~>3.0.11'

  gem 'blacklight', '~> 3.1.2'
  gem 'hydra-head', '~> 3.3.0'

  # We will assume that you're using sqlite3 for testing/demo, 
  # but in a production setup you probably want to use a real sql database like mysql or postgres
  gem 'sqlite3'

  #  We will assume you're using devise in tutorials/documentation. 
  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise'

  # For testing.  You will probably want to use all of these to run the tests you write for your hydra head
  group :development, :test do 
         gem 'solrizer-fedora', '>=1.2.2'
         gem 'ruby-debug'
         gem 'rspec'
         gem 'rspec-rails', '>=2.5.0'
         gem 'mocha'
         gem 'cucumber-rails'
         gem 'database_cleaner'
         gem 'capybara'
         gem 'bcrypt-ruby'
         gem "jettywrapper"

         # Added 
         gem 'net-http-digest_auth'
         gem 'rubyhorn', :git => "git://github.com/cjcolvar/rubyhorn.git"

  end # (leave this comment here to catch a stray line inserted by blacklight!)
