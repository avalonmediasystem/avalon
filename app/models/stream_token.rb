class StreamToken < ActiveRecord::Base
  class Unauthorized < Exception; end

  attr_accessible :token, :target, :expires
  
  def self.find_or_create_session_token(session, target)
    result = self.find_or_create_by_token_and_target(session[:session_id], target)
    result.renew!
    result.token
  end

  def self.validate_token(value)
    raise Unauthorized, "Unauthorized" if value.nil?

    (target, token_string) = value.scan(/^(.+)-(.+)$/).first
    token = self.find_by_token_and_target(token_string, target)
    if token.present? and token.expires > Time.now
      token.renew!
      return target
    else
      raise Unauthorized, "Unauthorized"
    end
  end

  def renew!
    self.update_attribute :expires, ( Time.now + Avalon::Configuration['streaming']['stream_token_ttl'].minutes )
  end
end
