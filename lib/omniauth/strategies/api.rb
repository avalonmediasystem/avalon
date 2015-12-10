require 'oauth'
require 'omniauth'
require 'oauth/request_proxy/rack_request'


module OmniAuth
  module Strategies
    class Api
      include OmniAuth::Strategy

      option :oauth_credentials, {}

      def callback_phase
byebug
	@token = request.params['api_key']
	unless options.oauth_credentials.include?(@token) #&& OAuth::Signature.verify(request, consumer_secret: @token)
	  fail!(:invalid_credentials)
          return
	end
	@account = options.oauth_credentials[@token]
        #unless @account[:ip] == request.remote_ip
	#  fail!(:invalid_credentials)
	#end
          
	super
      end

      uid { @account[:username] }

      info do
	{
	  name: @account[:uername],
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
