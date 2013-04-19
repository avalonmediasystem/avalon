# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class StreamToken < ActiveRecord::Base
  class Unauthorized < Exception; end

  attr_accessible :token, :target, :expires
  
  def self.find_or_create_session_token(session, target)
    self.purge_expired!
    result = self.find_or_create_by_token_and_target(session[:session_id], target)
    result.renew!
    result.token
  end

  def self.logout!(session)
    self.find_all_by_token(session[:session_id]).each &:delete
  end

  def self.purge_expired!
    self.where("expires <= :now", :now => Time.now).each &:delete
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
