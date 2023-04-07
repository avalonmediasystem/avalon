server_options = Settings.domain
server_options = case server_options
when String
  uri = URI.parse(server_options)
  { host: uri.host, port: uri.port, protocol: uri.scheme }
when Hash
  server_options
else
  server_options.to_hash
end

if server_options
  server_options.symbolize_keys!
  server_options.slice!(:host, :port, :protocol)

  Rails.application.config.to_prepare do
    Rails.application.routes.default_url_options.merge!( server_options )
    ActionMailer::Base.default_url_options.merge!( server_options )
    ApplicationController.default_url_options = server_options
    ActionController::Base.asset_host = URI("#{server_options[:protocol]}://#{server_options[:host]}:#{server_options[:port]}").to_s
  end

  # Required for rails 6+
  # See https://blog.saeloun.com/2019/10/31/rails-6-adds-guard-against-dns-rebinding-attacks.html
  Rails.application.config.hosts << server_options[:host]
  Rails.application.config.hosts += ENV['RAILS_ADDITIONAL_HOSTS'].split(',') if ENV['RAILS_ADDITIONAL_HOSTS'].present?
end
