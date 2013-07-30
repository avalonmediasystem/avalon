require 'about_page/matterhorn'

AboutPage.configure do |config|
  config.app          = { :name => Avalon.name, :version => Avalon::VERSION }
  config.environment  = AboutPage::Environment.new({ 
    'Ruby' => /^(RUBY|GEM_|rvm)/
  })
  config.request = AboutPage::RequestEnvironment.new({
    'HTTP Server' => /^(SERVER_|POW_)/
  })
  config.fedora       = AboutPage::Fedora.new(ActiveFedora::Base.connection_for_pid(0))
  config.solr         = AboutPage::Solr.new(ActiveFedora.solr.conn, :numDocs => 1)
  config.matterhorn   = AboutPage::Matterhorn.new(Rubyhorn)
  config.dependencies = AboutPage::Dependencies.new(1)
end
