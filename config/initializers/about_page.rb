AboutPage.configure do |config|
  config.app          = { :name => Avalon.name, :version => Avalon::VERSION }
  config.environment  = AboutPage::Environment.new({
    'Ruby/Rails' => /^(RUBY|RAILS|RACK|GEM_|rvm)/
  })
  config.request = AboutPage::RequestEnvironment.new({
    'HTTP Server' => /^(SERVER_|POW_)/
  })
  config.fedora           = AboutPage::Fedora.new(ActiveFedora.fedora.connection)
  config.solr             = AboutPage::Solr.new(ActiveFedora.solr.conn, :numDocs => 1)
  config.database         = Avalon::About::Database.new(User)
  config.mediainfo        = Avalon::About::MediaInfo.new(:version => '>=0.7.59')
  config.streaming_server = Avalon::About::HLSServer.new(Settings.streaming.http_base)
  config.sidekiq          = Avalon::About::Sidekiq.new(numProcesses: 1)
  config.redis            = Avalon::About::Redis.new(Redis.new(Rails.application.config.cache_store[1]))
  config.git_log          = AboutPage::GitLog.new(limit: 15) if Rails.env.development?
  config.dependencies     = AboutPage::Dependencies.new
end
