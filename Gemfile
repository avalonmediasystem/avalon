  source 'http://rubygems.org'

  gem 'iconv'
  gem 'rails', '~>3.2.3'
  gem 'builder', '~>3.0.0'

  gem 'hydra', "~> 6.1.0"
  gem 'bcrypt-ruby', '~> 3.0.0'

  gem 'avalon-workflow', git: 'https://github.com/avalonmediasystem/avalon-workflow.git', tag: 'avalon-r3'
  gem 'avalon-batch', '~> 0.2.2', git: "https://github.com/avalonmediasystem/avalon-batch.git", tag: 'avalon-r3'
  gem 'mediaelement_rails', git: 'https://github.com/avalonmediasystem/mediaelement_rails.git', tag: 'avalon-r3'
  gem 'mediaelement-qualityselector', git:'https://github.com/avalonmediasystem/mediaelement-qualityselector.git', tag: 'avalon-r3'
  gem 'media_element_thumbnail_selector', git: 'https://github.com/avalonmediasystem/media-element-thumbnail-selector', tag: 'avalon-r3'
  gem 'mediaelement-skin-avalon', git:'https://github.com/avalonmediasystem/mediaelement-skin-avalon.git', tag: 'avalon-r3'
  gem 'mediaelement-title', git:'https://github.com/avalonmediasystem/mediaelement-title.git', tag: 'avalon-r3'
  gem 'mediaelement-hd-toggle', git:'https://github.com/avalonmediasystem/mediaelement-hd-toggle.git', tag: 'avalon-r3'

  gem 'roo'

  gem 'multipart-post'  
  gem 'modal_logic'

  gem 'rubyzip', '0.9.9'
  gem 'hooks'

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

  gem 'avalon-about', git: "https://github.com/avalonmediasystem/avalon-about.git", tag: 'avalon-r3'

  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise', '~>3.0.3'
  #gem 'devise-guests'
  gem 'haml'

  gem "jettywrapper"
  gem 'rubyhorn', git: "https://github.com/avalonmediasystem/rubyhorn.git", tag: 'avalon-r3'
  gem 'felixwrapper', git: "https://github.com/avalonmediasystem/felixwrapper.git", tag: 'avalon-r3'
  gem 'red5wrapper', git: "https://github.com/avalonmediasystem/red5wrapper.git", tag: 'avalon-r3'

  gem 'validates_email_format_of'
  gem 'loofah'
  gem 'omniauth-identity'
  gem 'omniauth-lti', git: "https://github.com/avalonmediasystem/omniauth-lti.git", tag: 'avalon-r3'

  gem 'mediainfo'
  gem 'delayed_job_active_record'
  gem 'whenever', require: false
  gem 'with_locking'

  gem 'equivalent-xml'

  group :assets, :production do
    gem 'coffee-rails', "~> 3.2.1"
    gem 'uglifier', '>= 1.0.3'
    gem 'jquery-rails', "~> 2.1.4"
    gem 'compass-rails', '~> 1.0.0'
    gem 'compass-susy-plugin', '~> 0.9.0', require: 'susy'

    # For overriding the default interface with Twitter Bootstrap
    # This is now inherited from Blacklight
    gem 'sass-rails', '~> 3.2.3'
    gem 'font-awesome-sass-rails'
    gem 'twitter_bootstrap_form_for',
      git: "https://github.com/avalonmediasystem/twitter_bootstrap_form_for.git",
      branch: "bootstrap-2.0"
    gem 'handlebars_assets'
  end

  # For testing.  You will probably want to use these to run the tests you write for your hydra head
  group :development, :test do
    #gem 'better_errors'
    #gem 'binding_of_caller'
    gem 'meta_request'
    gem 'capistrano', '~>2.12.0'
    gem 'rvm-capistrano'
    gem 'database_cleaner', git: 'https://github.com/atomical/database_cleaner', branch: 'adding_support_for_active_fedora_orm', tag: 'avalon-r3'
    gem 'factory_girl_rails'
    gem 'rspec-rails', '>=2.9.0'
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
    gem 'simplecov'
    gem 'email_spec'
    gem 'capybara'
    gem 'shoulda-matchers'
    gem 'faker'
    gem 'fakefs', require: "fakefs/safe"
  end

  extra_gems = File.expand_path("../Gemfile.local",__FILE__)
  eval File.read(extra_gems) if File.exists?(extra_gems)
