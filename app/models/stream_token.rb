class StreamToken < ActiveRecord::Base
	attr_accessible :token, :target, :expires
  
  def self.find_or_create_session_token(session, target)
  	last_refresh = session['warden.user.user.session']['last_request_at']
  	result = self.find_or_create_by_token_and_target(session[:session_id], target)
	  result.update_attribute :expires, (last_refresh + 1.hour)
	  result.token
  end

  def self.validate_token(value)
  	(target, token_string) = value.scan(/^(.+)-(.+)$/).first
  	token = self.find_by_token_and_target(token_string, target)
  	if token.expires > Time.now
  		return target
  	else
  		raise "Unauthorized"
  	end
  end

end
