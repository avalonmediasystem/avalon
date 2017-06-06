source 'https://rubygems.org'
gem 'fedora-migrate', '~> 0.5.0'
gem 'rdf-rdfxml'

gem 'hydra-head', '~> 10.3.4'
gem 'active-fedora', '~> 11.2'
gem 'active_fedora-datastreams'
gem 'active_fedora-noid', '~> 2.0.2'
gem 'speedy-af', '~> 0.1.1'
gem 'blacklight', '~> 6.6'
gem 'rdf', '~> 2.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.9'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
gem 'sass', '3.4.22'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# Babel transpiling - See https://babeljs.io/docs/setup/#installation
gem 'sprockets-es6'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'rsolr', '~> 1.0'
gem 'devise'
#gem 'devise-guests', '~> 0.3'

# Avalon-specific
gem 'active_encode', git: "http://github.com/projecthydra-labs/active-encode.git"
gem 'avalon-workflow', git: "https://github.com/avalonmediasystem/avalon-workflow.git", branch: 'no_invalid_objs'
gem 'hooks'
gem 'iconv'
gem 'mediainfo', git: "https://github.com/avalonmediasystem/mediainfo.git", branch: 'remote_files'
gem 'omniauth-identity'
gem 'omniauth-lti', git: "https://github.com/avalonmediasystem/omniauth-lti.git", tag: 'avalon-r4'
gem 'ims-lti', '~> 1.1.13'
gem 'omniauth-openam'
gem 'net-ldap'
gem 'edtf'
gem 'rest-client'
gem 'active_annotations', '~> 0.2.2'
gem 'acts_as_list'
gem 'api-pagination'
gem 'browse-everything', '~> 0.13.0'
gem 'bootstrap_form'
gem 'bootstrap-toggle-rails', git: "https://github.com/rkallensee/bootstrap-toggle-rails.git"
gem 'rubyhorn', git: "https://github.com/avalonmediasystem/rubyhorn.git"
gem 'roo'
gem 'activerecord-session_store'
gem 'whenever', git: "https://github.com/javan/whenever.git", require: false
gem 'with_locking'
gem 'parallel'
gem 'avalon-about', git: 'https://github.com/avalonmediasystem/avalon-about.git', tag: 'avalon-r6'
gem 'about_page', git: 'https://github.com/avalonmediasystem/about_page.git', tag: 'avalon-r6.1'
gem 'jquery-datatables'
gem 'config'
gem 'marc'

#MediaElement.js related
gem 'mediaelement_rails', git: 'https://github.com/avalonmediasystem/mediaelement_rails.git', tag: 'avalon-r6_flash-fix'
gem 'mediaelement-qualityselector', git:'https://github.com/avalonmediasystem/mediaelement-qualityselector.git', tag: 'avalon-r4'
gem 'media_element_thumbnail_selector', git: 'https://github.com/avalonmediasystem/media-element-thumbnail-selector', tag: 'avalon-r4'
gem 'mediaelement-skin-avalon', git:'https://github.com/avalonmediasystem/mediaelement-skin-avalon.git', tag: 'avalon-r5'
gem 'mediaelement-title', git:'https://github.com/avalonmediasystem/mediaelement-title.git', tag: 'avalon-r4'
gem 'mediaelement-hd-toggle', git:'https://github.com/avalonmediasystem/mediaelement-hd-toggle.git', tag: 'avalon-r4'
gem 'media-element-logo-plugin'
gem 'media_element_add_to_playlist', git: 'https://github.com/avalonmediasystem/media-element-add-to-playlist.git', tag: 'avalon-r6.2'
gem 'mediaelement-track-scrubber', git: 'https://github.com/avalonmediasystem/mediaelement-track-scrubber.git', tag: 'avalon-r6'


gem 'resque', '~> 1.26.0'
gem 'resque-scheduler', '~> 4.3.0'
gem 'redis-rails'

group :production do
  gem 'lograge'
  gem 'google-analytics-rails', '1.1.0'
end

group :development, :test do
  gem 'equivalent-xml'
  gem 'rb-readline'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'solr_wrapper', '>= 0.16'
  gem 'fcrepo_wrapper'
  gem 'rspec-rails'
  gem 'dotenv-rails'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # ctrl+shift+x to see erb files rendered on page
  gem 'xray-rails'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  #gem 'spring'
  gem 'rubocop', '~> 0.40.0', require: false

  #Cap Deploys
  gem 'capistrano', '~>3.6'
  gem 'capistrano-rails', require: false
  gem 'capistrano-resque', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-passenger', require: false
end

group :profiling do
  gem 'rack-mini-profiler', require: false
  gem 'stackprof', require: false
  gem 'flamegraph', require: false
end

group :test do
  gem 'factory_girl_rails'
  gem 'simplecov'
  gem 'codeclimate-test-reporter'
  gem 'faker'
  gem 'database_cleaner'
  gem 'shoulda-matchers'
  gem 'fakefs', require: 'fakefs/safe'
  gem 'email_spec'
  gem 'capybara'
  gem 'poltergeist'
  gem 'rspec-retry'
  gem 'hashdiff'
  gem 'webmock'
end

group :aws, optional: true do
  gem 'aws-sdk', '~> 2.0'
  gem 'aws-sdk-rails'
  gem 'cloudfront-signer'
  gem 'zk'
  gem 'active_elastic_job', '~> 2.0'
end

group :zoom, optional: true do
  gem 'zoom'
end

group :mysql, optional: true do
  gem 'mysql2'
end
group :postgres, optional: true do
  gem 'pg'
end
group :ssl_dev, optional: true do
  gem 'puma'
end
group :ezid, optional: true do
  gem 'ezid-client'
end

extra_gems = File.expand_path("../Gemfile.local",__FILE__)
eval File.read(extra_gems) if File.exists?(extra_gems)
