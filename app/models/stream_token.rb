# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

#  attr_accessible :token, :target, :expires

  def self.media_token(session)
    session[:hash_tokens] ||= []
    session[:media_token] ||= SecureRandom.hex(16)
  end

  def self.find_or_create_session_token(session, target)
    self.purge_expired!
    hash_token = Digest::SHA1.new
    hash_token << media_token(session) << target
    result = self.find_or_create_by_token_and_target(hash_token.to_s, target)
    result.renew!
    session[:hash_tokens] << result.token
    result.token
  end

  def self.logout!(session)
    session[:hash_tokens].each { |sha|
      self.find_all_by_token(sha).each &:delete
    } unless session[:hash_tokens].nil?
  end

  def self.purge_expired!
    self.where("expires <= :now", :now => Time.now).each &:delete
  end

  def self.validate_token(value)
    raise Unauthorized, "Unauthorized" if value.nil?

    token = self.find_by_token(value)
    if token.present? and token.expires > Time.now
      token.renew!
      valid_streams = ActiveFedora::SolrService.query(%{is_derivation_of_ssim:"info:fedora/#{token.target}"}, fl: 'stream_path_ssi')
      return valid_streams.collect { |d| d['stream_path_ssi'] }
    else
      raise Unauthorized, "Unauthorized"
    end
  end

  def renew!
    self.update_attribute :expires, ( Time.now + Avalon::Configuration.lookup('streaming.stream_token_ttl').minutes )
  end
end
