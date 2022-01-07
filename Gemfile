source 'https://rubygems.org'

# Core rails
gem 'bootsnap', require: false
gem 'listen'
gem 'rails', '=5.2.6'
gem 'sprockets', '~>3.7.2'
gem 'sqlite3'

# Assets
gem 'coffee-rails', '~> 4.2.0'
gem 'jquery-datatables'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'react-rails'
gem 'sass-rails', '~> 5.0'
# Use the last known good version of sass
gem 'sass', '3.4.22'
gem 'sprockets-es6'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker'

# Core Samvera
gem 'active-fedora', '~> 13.2'
gem 'active_fedora-datastreams', '~> 0.3'
gem 'fedora-migrate', git: 'https://github.com/avalonmediasystem/fedora-migrate.git', tag: 'avalon-r6.5'
gem 'hydra-head', '~> 11.0'
gem 'ldp', '~> 0.3' 
gem 'noid-rails', '~> 3.0.1'
gem 'rdf-rdfxml'
gem 'rdf-vocab', '< 3.1.5'

# Samvera version pins
gem 'blacklight', '< 7.0'
gem 'rdf', '~> 3.1'
gem 'rsolr', '~> 1.0'

# Rails & Samvera Plugins
gem 'about_page', git: 'https://github.com/avalonmediasystem/about_page.git', tag: 'avalon-r6.5'
gem 'active_annotations', '~> 0.3'
gem 'activerecord-session_store', '>= 2.0.0'
gem 'acts_as_list'
gem 'api-pagination'
gem 'avalon-about', git: 'https://github.com/avalonmediasystem/avalon-about.git', tag: 'avalon-r6.4'
gem 'bootstrap-sass', '< 3.4.1' # Pin to less than 3.4.1 due to change in behavior with popovers
gem 'bootstrap-toggle-rails'
gem 'bootstrap_form'
gem 'iiif_manifest', '~> 0.6'
gem 'rack-cors', require: 'rack/cors'
gem 'rails_same_site_cookie'
gem 'recaptcha', require: 'recaptcha/rails'
gem 'samvera-persona', '~> 0.3'
gem 'speedy-af', '~> 0.1.3'

# Avalon Components
gem 'avalon-workflow', git: "https://github.com/avalonmediasystem/avalon-workflow.git", tag: 'avalon-r6.5'

# Authentication & Authorization
gem 'devise', '~> 4.8'
gem 'devise_invitable', '~> 2.0'
gem 'ims-lti', '~> 1.1.13'
gem 'net-ldap'
gem 'omniauth', '~> 2.0'
gem 'omniauth-identity', '>= 2.0.0'
gem 'omniauth-lti', git: "https://github.com/avalonmediasystem/omniauth-lti.git", tag: 'avalon-r4'
gem "omniauth-saml", "~> 2.0"

# Media Access & Transcoding
gem 'active_encode', '~> 0.8.2'
gem 'audio_waveform-ruby', '~> 1.0.7', require: 'audio_waveform'
gem 'browse-everything', git: "https://github.com/avalonmediasystem/browse-everything.git", branch: 'v0.16.1-gdrive-fixes'
gem 'fastimage'
gem 'media_element_add_to_playlist', git: 'https://github.com/avalonmediasystem/media-element-add-to-playlist.git', tag: 'avalon-r6.5'
gem 'mediainfo', git: "https://github.com/avalonmediasystem/mediainfo.git", branch: 'avalon_fixes'
gem 'rest-client', '~> 2.0'
gem 'roo'
gem 'wavefile', '~> 1.0.1'

# Data Translation & Normalization
gem 'edtf'
gem 'iconv', '~> 1.0.6'
gem 'marc'

# Jobs
gem 'activejob-traffic_control'
gem 'activejob-uniqueness'
gem 'redis-rails'
gem 'sidekiq', '~> 6.2'
gem 'sidekiq-cron', '~> 1.2'

# Coding Patterns
gem 'config'
gem 'hooks'
gem 'jbuilder', '~> 2.0'
gem 'parallel'
gem 'with_locking'

group :development do
  gem 'capistrano', '~>3.6'
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-sidekiq', require: false
  gem 'capistrano-yarn', require: false

  # Use Bixby instead of rubocop directly
  gem 'bixby', require: false
  gem 'web-console'
  gem 'xray-rails'
end

group :development, :test do
  gem 'byebug'
  gem 'dotenv-rails'
  gem 'equivalent-xml'
  gem 'fcrepo_wrapper'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rb-readline'
  gem 'rspec-rails'
  gem 'solr_wrapper', '>= 0.16'
end

group :test do
  gem 'capybara'
  gem 'codeclimate-test-reporter'
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'factory_bot_rails'
  gem 'fakefs', require: 'fakefs/safe'
  gem 'faker'
  gem 'hashdiff', ">= 1.0"
  gem 'rails-controller-testing'
  gem 'rspec-its'
  gem 'rspec-retry'
  gem 'rspec_junit_formatter'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov'
  gem 'webdrivers', '~> 3.0'
  gem 'webmock', '~> 3.5.1'
end

group :production do
  gem 'google-analytics-rails', '1.1.0'
  gem 'lograge'
  gem 'okcomputer'
  gem 'puma', '>= 4.3.8'
end

# Install the bundle --with aws when running on Amazon Elastic Beanstalk
group :aws, optional: true do
  gem 'active_elastic_job', github: 'tawan/active-elastic-job'
  gem 'aws-partitions'
  gem 'aws-sdk-rails'
  gem 'aws-sdk-cloudfront'
  gem 'aws-sdk-elastictranscoder'
  gem 'aws-sdk-s3'
  gem 'aws-sdk-ses'
  gem 'aws-sdk-sqs'
  gem 'aws-sigv4'
  gem 'cloudfront-signer'
  gem 'zk'
end

# Install the bundle --with zoom to use the Z39.50 bib retriever
group :zoom, optional: true do
  gem 'zoom'
end

# Install the bundle --with postgres if using postgresql as the database backend
group :postgres, optional: true do
  gem 'pg'
end

# Install the bundle --with mysql if using mysql as the database backend
group :mysql, optional: true do
  gem 'mysql2'
end

extra_gems = File.expand_path("../Gemfile.local", __FILE__)
eval File.read(extra_gems) if File.exist?(extra_gems)
