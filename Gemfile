source 'https://rubygems.org'

# Core rails
gem 'bootsnap', require: false
gem 'listen'
gem 'net-smtp', require: false
gem 'psych', '< 4'
gem 'rails', '~>7.0.8'
gem 'sprockets', '~>3.7.2'
#gem 'sprockets-rails', require: 'sprockets/railtie'
gem 'sqlite3'
# Force newer version of mail for compatibility with rails 6.0.6.1
gem 'mail', '> 2.8.0.1'

# Assets
gem 'bootstrap', '~> 4.0'
gem 'coffee-rails', '~> 5.0'
gem "font-awesome-rails"
gem 'jquery-datatables'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'react-rails'
#gem 'sass-rails', '>= 6'
# Use the last known good version of sass
gem 'sass', '3.4.22'
gem 'sprockets-es6'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'terser'
gem 'shakapacker'

# Core Samvera
gem 'active-fedora', '~> 14.0', '>= 14.0.1'
gem 'active_fedora-datastreams', '~> 0.5'
gem 'hydra-head', '~> 12.0'
gem 'ldp', '~> 1.1.0'
gem 'noid-rails', '~> 3.1'
gem 'om', git: 'https://github.com/avalonmediasystem/om.git', tag: 'v3.2.0-ruby3'
gem 'rdf-rdfxml'

# Samvera version pins
gem 'blacklight', '~> 7.25'
gem 'blacklight-access_controls', '>= 6.0.1' # ensure rails 6 support
gem 'rdf', '~> 3.1'
gem 'rsolr', '~> 2.0'

# Rails & Samvera Plugins
gem 'about_page', git: 'https://github.com/avalonmediasystem/about_page.git', tag: 'avalon-r6.5'
gem 'active_annotations', '~> 0.4'
gem 'activerecord-session_store', '>= 2.0.0'
gem 'acts_as_list'
gem 'api-pagination'
gem 'avalon-about', git: 'https://github.com/avalonmediasystem/avalon-about.git', tag: 'avalon-r7.7'
#gem 'bootstrap-sass', '< 3.4.1' # Pin to less than 3.4.1 due to change in behavior with popovers
gem 'bootstrap-toggle-rails'
gem 'bootstrap_form'
gem 'iiif_manifest', '~> 1.5'
gem 'rack-cors', require: 'rack/cors'
gem 'rails_same_site_cookie'
gem 'recaptcha', require: 'recaptcha/rails'
gem 'samvera-persona', '~> 0.4', '>= 0.4.1'
gem 'speedy-af', '~> 0.3'

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
gem 'active_encode', '>= 1.2.2'
gem 'audio_waveform-ruby', '~> 1.0.7', require: 'audio_waveform'
gem 'browse-everything', git: "https://github.com/avalonmediasystem/browse-everything.git", branch: 'v1.2-avalon'
gem 'fastimage'
gem 'mediainfo', git: "https://github.com/avalonmediasystem/mediainfo.git", tag: 'v0.7.1-avalon'
gem 'rest-client', '~> 2.0'
gem 'roo'
gem 'wavefile', '~> 1.0.1'

# Data Translation & Normalization
gem 'edtf', '>= 3.1.1'
gem 'iconv', '~> 1.0.6'
gem 'marc'

# Jobs
gem 'activejob-traffic_control'
gem 'activejob-uniqueness'
gem 'redis-rails'
gem 'sidekiq', '~> 6.2'
gem 'sidekiq-cron', '~> 1.9'

# Coding Patterns
gem 'config'
gem 'hooks'
gem 'jbuilder', '~> 2.0'
gem 'parallel'
gem 'with_locking'

# Reindexing script
gem 'sequel'
gem 'httpx'

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
  gem 'webmock', '~> 3.5'
end

group :production do
  gem 'google-analytics-rails', '1.1.0'
  gem 'lograge'
  gem 'okcomputer'
  gem 'puma', '>= 6.4.2'
end

# Install the bundle --with aws when running on Amazon Elastic Beanstalk
group :aws, optional: true do
  gem 'active_elastic_job'
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
