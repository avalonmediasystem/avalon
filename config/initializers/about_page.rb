AboutPage.configure do |config|
  config.app          = { :name => Avalon.name, :version => Avalon::VERSION }
  config.environment  = AboutPage::Environment.new({ 
    'Ruby/Rails' => /^(RUBY|RAILS|RACK|GEM_|rvm)/
  })
  config.request = AboutPage::RequestEnvironment.new({
    'HTTP Server' => /^(SERVER_|POW_)/
  })
  config.fedora           = AboutPage::Fedora.new(ActiveFedora::Base.connection_for_pid(0))
  config.solr             = AboutPage::Solr.new(ActiveFedora.solr.conn, :numDocs => 1)
  config.database         = Avalon::About::Database.new(User)
  config.matterhorn       = Avalon::About::Matterhorn.new(Rubyhorn)
  config.mediainfo        = Avalon::About::MediaInfo.new(:version => '>=0.7.59')
  config.streaming_server = Avalon::About::RTMPServer.new(URI.parse(Avalon::Configuration.lookup('streaming.rtmp_base')).host)
  config.delayed_job      = Avalon::About::DelayedJob.new(:min => 1)
  config.git_log          = AboutPage::GitLog.new(limit: 15) if Rails.env.development?
  config.dependencies     = AboutPage::Dependencies.new
end
