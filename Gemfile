  source 'http://rubygems.org'

  gem 'iconv'
  gem 'rails', '~>4.0.3'
  gem 'sprockets', '~>2.11.0'
  #gem 'protected_attributes'
  gem 'builder', '~>3.1.0'

  gem 'hydra', '~>7.1'
  gem 'active-fedora'
  gem 'activerecord-session_store'
  gem 'bcrypt-ruby', '~> 3.1.0'
  gem 'kaminari', '~> 0.15.0'

  gem 'avalon-workflow', git: 'https://github.com/avalonmediasystem/avalon-workflow.git', tag: 'avalon-r3'
  gem 'avalon-batch', git: "https://github.com/avalonmediasystem/avalon-batch.git", tag: 'v3.1'
  gem 'mediaelement_rails', git: 'https://github.com/avalonmediasystem/mediaelement_rails.git', tag: 'v3.1' # HEAD , tag: 'avalon-r3'
  gem 'mediaelement-qualityselector', git:'https://github.com/avalonmediasystem/mediaelement-qualityselector.git' # HEAD , tag: 'avalon-r3'
  gem 'media_element_thumbnail_selector', git: 'https://github.com/avalonmediasystem/media-element-thumbnail-selector', tag: 'v3.1'
  gem 'mediaelement-skin-avalon', git:'https://github.com/avalonmediasystem/mediaelement-skin-avalon.git' # HEAD , tag: 'avalon-r3'
  gem 'mediaelement-title', git:'https://github.com/avalonmediasystem/mediaelement-title.git' # HEAD , tag: 'avalon-r3'
  gem 'mediaelement-hd-toggle', git:'https://github.com/avalonmediasystem/mediaelement-hd-toggle.git' # HEAD , tag: 'avalon-r3'
  gem 'media-element-logo-plugin'

  gem 'browse-everything', '>= 0.6.3'
  
  gem 'roo', git: 'https://github.com/Empact/roo', ref: '9e1b969762cbb80b1c52cfddd848e489f22f468f'

  gem 'multipart-post'  
  gem 'modal_logic'
  
  gem 'rubyzip', '0.9.9'
  gem 'hooks'

  # microdata
  gem 'ruby-duration'

  platforms :jruby do
    gem 'jruby-openssl'
    gem 'activerecord-jdbcsqlite3-adapter'
    gem 'jdbc-sqlite3'
    gem 'therubyrhino'
  end

  platforms :ruby do
    gem 'sqlite3'
    gem 'execjs'
    gem 'therubyracer', '>= 0.12.0'
  end

  gem 'avalon-about', git: "https://github.com/avalonmediasystem/avalon-about.git", tag: 'v3.1'
  gem 'about_page', git: "https://github.com/avalonmediasystem/about_page.git"

  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise', '~>3.2.0'
  #gem 'devise-guests'
  gem 'haml'

  gem "jettywrapper"
  gem 'rubyhorn', git: "https://github.com/avalonmediasystem/rubyhorn.git" # HEAD , tag: 'avalon-r3'
  gem 'felixwrapper', git: "https://github.com/avalonmediasystem/felixwrapper.git", tag: 'v3.1' # HEAD , tag: 'avalon-r3'
  gem 'red5wrapper', git: "https://github.com/avalonmediasystem/red5wrapper.git", tag: 'v3.1' # HEAD , tag: 'avalon-r3'

  gem 'validates_email_format_of'
  gem 'loofah'
  gem 'omniauth-identity'
  gem 'omniauth-lti', git: "https://github.com/avalonmediasystem/omniauth-lti.git", tag: 'v3.1' # HEAD , tag: 'avalon-r3'

  gem 'mediainfo'
  gem 'delayed_job_active_record'
  gem 'whenever', require: false
  gem 'with_locking'

  gem 'equivalent-xml'
  gem 'net-ldap'

  group :assets, :production do
    gem 'coffee-rails'
    gem 'uglifier', '>= 1.0.3'
    gem 'jquery-rails', '3.1.1'
    gem 'jquery-ui-rails', '5.0.0'
    gem 'compass-rails'
    gem 'compass-susy-plugin', '~> 0.9.0', require: 'susy'

    # For overriding the default interface with Twitter Bootstrap
    # This is now inherited from Blacklight
    gem 'sass-rails', '=4.0.2'
    gem 'font-awesome-rails', '~> 3.0'
    gem 'bootstrap_form'
    gem 'handlebars_assets'
    gem 'twitter-typeahead-rails'
  end

  group :development do
    gem 'xray-rails'
    gem 'better_errors'
    gem 'binding_of_caller'
  end

  # For testing.  You will probably want to use these to run the tests you write for your hydra head
  group :development, :test do
    gem 'meta_request'
    gem 'capistrano', '~>2.12.0'
    gem 'rvm-capistrano'
    gem 'database_cleaner', git: 'https://github.com/atomical/database_cleaner', branch: 'adding_support_for_active_fedora_orm' # HEAD , tag: 'avalon-r3'
    gem 'factory_girl_rails'
    gem 'rspec-rails', '~>2.9'
    gem 'pry'
    gem 'pry-rails'
    gem 'pry-debugger'
    gem 'puma'
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
    gem 'rspec-its'
    gem 'simplecov'
    gem 'email_spec'
    gem 'capybara'
    gem 'shoulda-matchers'
    gem 'faker'
    gem 'fakefs', require: "fakefs/safe"
  end

  extra_gems = File.expand_path("../Gemfile.local",__FILE__)
  eval File.read(extra_gems) if File.exists?(extra_gems)
