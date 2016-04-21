Rails.application.config.middleware.use OmniAuth::Builder do
  provider :cas, 
   host: 'secure.its.yale.edu',
   login_url: '/cas/login',
   service_validate_url: '/cas/serviceValidate',
   disable_ssl_verification: true,
   logout_url: '/cas/logout'
end
