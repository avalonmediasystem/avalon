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
  config.matterhorn       = Avalon::About::Matterhorn.new(Rubyhorn)
  config.mediainfo        = Avalon::About::MediaInfo.new(:version => '>=0.7.59')
  config.streaming_server = Avalon::About::HLSServer.new(Settings.streaming.http_base)
  config.resque           = Avalon::About::Resque.new(::Resque)
  config.resque_scheduler = Avalon::About::ResqueScheduler.new(::Resque::Scheduler)
  config.git_log          = AboutPage::GitLog.new(limit: 15) if Rails.env.development?
  config.dependencies     = AboutPage::Dependencies.new
end
