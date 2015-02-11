server_options = Avalon::Configuration.lookup('domain')

if server_options
  server_options.symbolize_keys!
  server_options.slice!(:host, :port, :protocol)

  Rails.application.routes.default_url_options.merge!( server_options )
  ActionMailer::Base.default_url_options.merge!( server_options )
  ApplicationController.default_url_options = server_options
end
