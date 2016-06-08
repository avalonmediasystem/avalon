  source 'http://rubygems.org'

  # active anno dev
  gem 'active_annotations', git: 'https://github.com/avalonmediasystem/active_annotations.git'

  gem 'iconv'
  gem 'rails', '~>4.0.3'
  gem 'sprockets', '~>2.11.0'
  #gem 'protected_attributes'
  gem 'builder', '~>3.1.0'
  gem 'rake', '~>10.4'

#  gem 'hydra', '~>8.0'
  gem 'hydra-head', git: 'https://github.com/avalonmediasystem/hydra-head.git', branch: '8-1-stable'
  gem 'active-fedora', '~> 8.1.0'
  gem 'om', '~> 3.1.0'
  gem 'solrizer', '~> 3.3.0'
  gem 'rsolr', '~> 1.0.12'
  gem 'blacklight', '~> 5.10'
  gem 'nokogiri', '~> 1.6.5'
  gem 'rubydora', '~> 1.8.1'
  gem 'nom-xml', '~> 0.5.2'

  gem 'activerecord-session_store'
  gem 'bcrypt-ruby', '~> 3.1.0'
  gem 'kaminari', '~> 0.15.0'

  gem 'avalon-workflow', git: 'https://github.com/avalonmediasystem/avalon-workflow.git', tag: 'avalon-r4'
  gem 'mediaelement_rails', git: 'https://github.com/avalonmediasystem/mediaelement_rails.git', tag: 'captions'
  gem 'mediaelement-qualityselector', git:'https://github.com/avalonmediasystem/mediaelement-qualityselector.git', tag: 'avalon-r4'
  gem 'media_element_thumbnail_selector', git: 'https://github.com/avalonmediasystem/media-element-thumbnail-selector', tag: 'avalon-r4'
  gem 'mediaelement-skin-avalon', git:'https://github.com/avalonmediasystem/mediaelement-skin-avalon.git', tag: 'captions'
  gem 'mediaelement-title', git:'https://github.com/avalonmediasystem/mediaelement-title.git', tag: 'avalon-r4'
  gem 'mediaelement-hd-toggle', git:'https://github.com/avalonmediasystem/mediaelement-hd-toggle.git', tag: 'avalon-r4'
  gem 'media-element-logo-plugin'
  gem 'media_element_add_to_playlist', git: 'https://github.com/avalonmediasystem/media-element-add-to-playlist.git'

  gem 'browse-everything', '0.6.3'

  gem 'roo', git: 'https://github.com/Empact/roo', ref: '9e1b969762cbb80b1c52cfddd848e489f22f468f'

  gem 'multipart-post'
  gem 'modal_logic'

  gem 'rubyzip', '0.9.9'
  gem 'hooks'
  gem 'addressable'
  gem 'acts_as_list'

  # microdata
  gem 'ruby-duration'
  gem 'edtf'

# Uncomment the following line to include z39.59/zoom support in Avalon::BibRetriever
# NOTE: Requires the yaz library to be installed
#  gem 'zoom', '~>0.4.1', :git => 'https://github.com/bricestacey/ruby-zoom.git'

  gem 'marc'

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

  gem 'avalon-about', git: "https://github.com/avalonmediasystem/avalon-about.git", tag: 'avalon-r4'
  gem 'about_page', git: "https://github.com/avalonmediasystem/about_page.git", tag: 'avalon-r4'

  # You are free to implement your own User/Authentication solution in its place.
  gem 'devise', '~>3.2.0'
  #gem 'devise-guests'
  gem 'haml'

  gem 'active_encode', git: "https://github.com/projecthydra-labs/active_encode.git"
  gem 'rubyhorn', git: "https://github.com/avalonmediasystem/rubyhorn.git"
  gem 'validates_email_format_of'
  gem 'loofah'
  gem 'omniauth-identity'
  gem 'omniauth-lti', git: "https://github.com/avalonmediasystem/omniauth-lti.git", tag: 'avalon-r4'

  gem 'mediainfo'
  gem 'delayed_job', '=4.0.4'
  gem 'delayed_job_active_record'
  gem 'whenever', require: false
  gem 'with_locking'

  gem 'equivalent-xml'
  gem 'net-ldap'

  gem 'api-pagination'

  group :assets, :production do
    gem 'coffee-rails'
    gem 'uglifier', '>= 1.0.3'
    gem 'jquery-rails', '3.1.1'
    gem 'jquery-ui-rails', '5.0.0'
    gem 'compass-rails'
    gem 'compass-susy-plugin', '~> 0.9.0', require: 'susy'

    # For overriding the default interface with Twitter Bootstrap
    # This is now inherited from Blacklight
    gem 'bootstrap-sass', '=3.3.3'
    gem 'sass-rails', '=4.0.3'
    gem 'font-awesome-rails', '~> 4.3'
    gem 'bootstrap_form'
    gem 'handlebars_assets'
    #gem 'twitter-typeahead-rails', '~>0.11.1'
    gem 'twitter-typeahead-rails', '= 0.11.1.pre.corejavascript'
  end

  group :development do
    gem 'xray-rails'
    gem 'better_errors',   platforms: [:mri_20, :mri_21]
    gem 'binding_of_caller',   platforms: [:mri_20, :mri_21]
    gem 'license_header'
    gem 'meta_request'
    gem 'capistrano', '~>2.12.0'
    gem 'rvm-capistrano', require: false
    gem 'rubocop', '~> 0.40.0', require: false
  end

  # For testing.  You will probably want to use these to run the tests you write for your hydra head
  group :development, :test do
    gem "jettywrapper"
    gem 'felixwrapper', git: "https://github.com/avalonmediasystem/felixwrapper.git", tag: 'avalon-r4'
    gem 'red5wrapper', git: "https://github.com/avalonmediasystem/red5wrapper.git", tag: 'avalon-r4'
    gem 'daemons'
    gem 'rspec-rails'
    gem 'puma'
    gem 'rb-fsevent', '~> 0.9.1'
    gem 'letter_opener'
    gem 'pry'
    gem 'pry-rails'
  end # (leave this comment here to catch a stray line inserted by blacklight!)

  group :debug do
    gem 'pry-debugger', platforms: [:mri_19]
    gem 'pry-byebug',   platforms: [:mri_20, :mri_21]
  end

  group :test do
    gem 'database_cleaner', git: 'https://github.com/avalonmediasystem/database_cleaner.git', tag: 'avalon-r4'
    gem 'factory_girl_rails'
    gem 'mime-types', ">=1.1"
    gem "headless"
    gem 'simplecov'
    gem 'email_spec'
    gem 'capybara'
    gem 'shoulda-matchers'
    gem 'faker'
    gem 'fakefs', require: "fakefs/safe"
    gem 'fakeweb'
    gem 'hashdiff'
    gem 'coveralls'
  end

  extra_gems = File.expand_path("../Gemfile.local",__FILE__)
  eval File.read(extra_gems) if File.exists?(extra_gems)
