require 'oauth'

module Avalon
  module OmniAuth
    module Strategies
      class JsonApi
        include OmniAuth::Strategy

        option :oauth_credentials, {}

        def callback_phase
          @token = request.params['api_key']
          unless oauth_credentials.include?(@token) && Oauth::Signature.verify(request, consumer_secret: @token)
            fail!(:invalid_credentials)
          end
          @account = oauth_credentials[token]
          super
        end

        uid { @account[:username] }

        info do
          {
            name: @account[:uername]
            email: @account[:email]
          }
        end

        credentials do
          {
            token: @token
          }
        end
      end
    end
  end
end
