server_options = Settings.domain
server_options = case server_options
when String
  uri = URI.parse(server_options)
  { host: uri.host, port: uri.port, procotol: uri.scheme }
when Hash
  server_options
else
  server_options.to_hash
end

if server_options
  server_options.symbolize_keys!
  server_options.slice!(:host, :port, :protocol)

  Rails.application.routes.default_url_options.merge!( server_options )
  ActionMailer::Base.default_url_options.merge!( server_options )
  ApplicationController.default_url_options = server_options
end
