module Faraday
  class Request
    class ResolveDns < Faraday::Middleware

      def initialize(app, options = {})
        super(app)
      end

      def call(env)
        srv = env[:url].hostname
        Resolv::DNS.new.getresources(srv, Resolv::DNS::Resource::IN::ANY).collect do |resource|
          env[:url].hostname = resource.target
          env[:url].port = resource.port

          env[:request_headers] ||= {}
          env[:request_headers]['Host'] = "#{srv}"
          return @app.call(env)
        end
      end
    end
  end
end
Faraday::Request.register_middleware resolve_dns: Faraday::Request::ResolveDns

module FaradayConnectionOptions
  def new_builder(block)
    super.tap do |builder|
      builder.request(:resolve_dns)
    end
  end
end
Faraday::ConnectionOptions.prepend(FaradayConnectionOptions)
