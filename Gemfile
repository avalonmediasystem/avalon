source 'https://rubygems.org'
gem 'fedora-migrate', git: 'https://github.com/projecthydra-labs/fedora-migrate.git'
gem 'rdf-rdfxml'

gem 'hydra-head', '~> 10.3.4'
gem 'active-fedora', '>= 10.3.0'
gem 'active_fedora-datastreams'
gem 'active_fedora-noid', '~> 2.0.0'
gem 'blacklight', '~> 6.6'
gem 'rdf-rdfxml'
gem 'rdf', '~> 2.1.1'
gem 'ldp', git:'https://github.com/projecthydra/ldp.git'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.7.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
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
gem 'avalon-workflow', git: "https://github.com/avalonmediasystem/avalon-workflow.git", branch: 'hydra10'
gem 'active_encode', '~> 0.0.3'
gem 'hooks'
gem 'iconv'
gem 'mediainfo', git: "https://github.com/avalonmediasystem/mediainfo.git", branch: 'avalon_fixes'
gem 'omniauth-identity'
gem 'omniauth-lti', git: "https://github.com/avalonmediasystem/omniauth-lti.git", tag: 'avalon-r4'
gem 'net-ldap'
gem 'edtf'
gem 'rest-client'
gem 'active_annotations', '~> 0.2.0'
gem 'acts_as_list'
gem 'api-pagination'
gem 'browse-everything', '~> 0.10.5'
gem 'bootstrap_form'
gem 'rubyhorn', git: "https://github.com/avalonmediasystem/rubyhorn.git"
gem 'roo'
gem 'activerecord-session_store'
gem 'whenever', git: "https://github.com/javan/whenever.git", require: false
gem 'with_locking'
gem 'parallel'
gem 'avalon-about', git: "https://github.com/avalonmediasystem/avalon-about.git", tag: "avalon-r6"
gem 'about_page', git: "https://github.com/avalonmediasystem/about_page.git", tag: "avalon-r6"

#MediaElement.js related
gem 'mediaelement_rails', git: 'https://github.com/avalonmediasystem/mediaelement_rails.git', branch: 'captions'
gem 'mediaelement-qualityselector', git:'https://github.com/avalonmediasystem/mediaelement-qualityselector.git', tag: 'avalon-r4'
gem 'media_element_thumbnail_selector', git: 'https://github.com/avalonmediasystem/media-element-thumbnail-selector', tag: 'avalon-r4'
gem 'mediaelement-skin-avalon', git:'https://github.com/avalonmediasystem/mediaelement-skin-avalon.git', tag: 'avalon-r5'
gem 'mediaelement-title', git:'https://github.com/avalonmediasystem/mediaelement-title.git', tag: 'avalon-r4'
gem 'mediaelement-hd-toggle', git:'https://github.com/avalonmediasystem/mediaelement-hd-toggle.git', tag: 'avalon-r4'
gem 'media-element-logo-plugin'
gem 'media_element_add_to_playlist', git: 'https://github.com/avalonmediasystem/media-element-add-to-playlist.git', branch: 'master'
gem 'mediaelement-track-scrubber', git: 'https://github.com/avalonmediasystem/mediaelement-track-scrubber.git', branch: 'master'


gem 'resque', '~> 1.26.0'
gem 'resque-scheduler', '~> 4.3.0'

group :development, :test do
  gem 'equivalent-xml'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'rb-readline'
  gem 'byebug'
  gem 'rb-readline'
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

group :test do
  gem 'factory_girl_rails'
  gem 'simplecov'
  gem 'faker'
  gem 'database_cleaner'
  gem 'coveralls'
  gem 'shoulda-matchers'
  gem 'fakefs', require: 'fakefs/safe'
  gem 'fakeweb'
  gem 'email_spec'
  gem 'capybara'
  gem 'hashdiff'
end

group :mysql, optional: true do
  gem 'mysql2'
end
group :postgres, optional: true do
  gem 'pg'
end

extra_gems = File.expand_path("../Gemfile.local",__FILE__)
eval File.read(extra_gems) if File.exists?(extra_gems)
