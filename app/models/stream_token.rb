# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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
  scope :expired, proc { where('expires <= :now', now: Time.now.utc) }
  class Unauthorized < Exception; end

  #  attr_accessible :token, :target, :expires

  def self.media_token(session)
    session[:hash_tokens] ||= []
    session[:media_token] ||= SecureRandom.hex(16)
  end

  def self.find_or_create_session_token(session, target)
    purge_expired!
    hash_token = Digest::SHA1.new
    hash_token << media_token(session) << target
    result = find_or_create_by!(token: hash_token.to_s, target: target)
    result.renew!
    session[:hash_tokens] << result.token
    session[:hash_tokens].uniq! # Avoid duplicate entry
    result.token
  end

  def self.logout!(session)
    session[:hash_tokens].each do |sha|
      where(token: sha).find_each(&:delete)
    end unless session[:hash_tokens].nil?
  end

  def self.purge_expired!
    expired.each(&:delete)
  end

  def self.validate_token(value)
    raise Unauthorized, 'Unauthorized' if value.nil?

    token = find_by_token(value)
    if token&.expires.present? && token.expires > Time.now.utc
      token.renew!
      valid_streams = ActiveFedora::SolrService.query(%(isDerivationOf_ssim:"#{token.target}"), fl: 'stream_path_ssi', rows: 10)
      return valid_streams.collect { |d| d['stream_path_ssi'] }
    else
      raise Unauthorized, 'Unauthorized'
    end
  end

  def self.valid_token?(value, master_file_id)
    return false if value.nil?
    token = find_by_token(value)
    token.present? && token.expires > Time.now.utc && token.target == master_file_id
  end

  def renew!
    update_attribute :expires, (Time.now.utc + Settings.streaming.stream_token_ttl.minutes)
  end
end
