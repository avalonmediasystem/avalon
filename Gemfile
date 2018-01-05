source 'https://rubygems.org'

# Core rails
gem 'rails', '4.2.9'
gem 'sqlite3'

# Assets
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-datatables'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'sass-rails', '~> 5.0'
# Use the last known good version of sass
gem 'sass', '3.4.22'
gem 'sprockets-es6'
gem 'uglifier', '>= 1.3.0'

# Core Samvera
gem 'hydra-head', '~> 10.3.4'
gem 'active-fedora', '~> 11.2'
gem 'active_fedora-datastreams'
gem 'active_fedora-noid', '~> 2.0.2'
gem 'fedora-migrate', '~> 0.5.0'
gem 'rdf-rdfxml'

# Samvera version pins
gem 'blacklight', '=6.13.0'
gem 'rdf', '~> 2.2'
gem 'rsolr', '~> 1.0'

# Rails & Samvera Plugins
gem 'about_page', git: 'https://github.com/avalonmediasystem/about_page.git', tag: 'avalon-r6.1'
gem 'active_annotations', '~> 0.2.2'
gem 'activerecord-session_store'
gem 'acts_as_list'
gem 'api-pagination'
gem 'avalon-about', git: 'https://github.com/avalonmediasystem/avalon-about.git', tag: 'avalon-r6'
gem 'bootstrap-toggle-rails', git: 'https://github.com/rkallensee/bootstrap-toggle-rails.git', tag: 'v2.2.1.0'
gem 'bootstrap_form'
gem 'speedy-af', '~> 0.1.1'

# Avalon Components
gem 'avalon-workflow', git: "https://github.com/avalonmediasystem/avalon-workflow.git", tag: 'avalon-r6.2'

# Authentication & Authorization
gem 'devise'
gem 'ims-lti', '~> 1.1.13'
gem 'net-ldap'
gem 'omniauth-identity'
gem 'omniauth-lti', git: "https://github.com/avalonmediasystem/omniauth-lti.git", tag: 'avalon-r4'

# Media Access & Transcoding
gem 'active_encode', '~> 0.1.1'
gem 'browse-everything', '~> 0.13.0'
gem 'mediainfo', git: "https://github.com/avalonmediasystem/mediainfo.git", branch: 'avalon_fixes'
gem 'rest-client'
gem 'roo'
gem 'rubyhorn', git: "https://github.com/avalonmediasystem/rubyhorn.git", tag: 'avalon-r6'

# Data Translation & Normalization
gem 'edtf'
gem 'iconv'
gem 'marc'

# MediaElement.js & Plugins
gem 'mediaelement_rails', git: 'https://github.com/avalonmediasystem/mediaelement_rails.git', tag: 'avalon-r6_flash-fix'
gem 'media-element-logo-plugin'
gem 'media_element_add_to_playlist', git: 'https://github.com/avalonmediasystem/media-element-add-to-playlist.git', tag: 'avalon-r6.2'
gem 'media_element_thumbnail_selector', git: 'https://github.com/avalonmediasystem/media-element-thumbnail-selector', tag: 'avalon-r4'
gem 'mediaelement-hd-toggle', git:'https://github.com/avalonmediasystem/mediaelement-hd-toggle.git', tag: 'avalon-r6.3'
gem 'mediaelement-qualityselector', git:'https://github.com/avalonmediasystem/mediaelement-qualityselector.git', tag: 'avalon-r4'
gem 'mediaelement-skin-avalon', git:'https://github.com/avalonmediasystem/mediaelement-skin-avalon.git', tag: 'avalon-r5'
gem 'mediaelement-title', git:'https://github.com/avalonmediasystem/mediaelement-title.git', tag: 'avalon-r4'
gem 'mediaelement-track-scrubber', git: 'https://github.com/avalonmediasystem/mediaelement-track-scrubber.git', tag: 'avalon-r6'

# Jobs
gem 'redis-rails'
gem 'resque', '~> 1.27.0'
gem 'resque-scheduler', '~> 4.3.0'

# Coding Patterns
gem 'config'
gem 'hooks'
gem 'jbuilder', '~> 2.0'
gem 'parallel'
gem 'whenever', git: "https://github.com/javan/whenever.git", require: false
gem 'with_locking'

group :development do
  gem 'capistrano', '~>3.6'
  gem 'capistrano-rails', require: false
  gem 'capistrano-resque', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-passenger', require: false

  # Use Bixby instead of rubocop directly
  gem 'bixby', require: false
  gem 'web-console', '~> 2.0'
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
  gem 'factory_girl_rails'
  gem 'fakefs', require: 'fakefs/safe'
  gem 'faker'
  gem 'hashdiff'
  gem 'poltergeist'
  gem 'rspec-retry'
  gem 'shoulda-matchers'
  gem 'simplecov'
  gem 'webmock'
end

group :production do
  gem 'google-analytics-rails', '1.1.0'
  gem 'lograge'
end

# Install the bundle --with aws when running on Amazon Elastic Beanstalk
group :aws, optional: true do
  gem 'aws-sdk', '~> 2.0'
  gem 'aws-sdk-rails'
  gem 'cloudfront-signer'
  gem 'zk'
  gem 'active_elastic_job', '~> 2.0'
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

extra_gems = File.expand_path("../Gemfile.local",__FILE__)
eval File.read(extra_gems) if File.exists?(extra_gems)
