# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
  class_attribute :max_tokens_per_user
  self.max_tokens_per_user = 2000

  def self.media_token(session)
    session[:hash_tokens] ||= []
    session[:media_token] ||= SecureRandom.hex(16)
  end

  def self.find_or_create_session_token(session, target)
    purge_expired!(session)
    hash_token = Digest::SHA1.new
    hash_token << media_token(session) << target
    result = find_or_create_by!(token: hash_token.to_s, target: target)
    result.renew!
    session[:hash_tokens] << result.token
    session[:hash_tokens].uniq! # Avoid duplicate entry
    result.token
  end

  def self.get_session_tokens_for(session: {}, targets: [])
    purge_expired!(session)

    token_attributes = targets.collect do |target|
      hash_token = Digest::SHA1.new
      hash_token << media_token(session) << target
      {target: target, token: hash_token.to_s, expires: (Time.now.utc + Settings.streaming.stream_token_ttl.minutes)}
    end
    existing_token_hash = StreamToken.where(token: token_attributes.pluck(:token)).pluck(:token, :id).to_h

    # Create new records first
    insert_attributes = token_attributes.reject { |attrs| existing_token_hash[attrs[:token]].present? }
    if insert_attributes.present?
      StreamToken.insert_all(insert_attributes)
      # Refetch so we have the ids of all tokens
      existing_token_hash = StreamToken.where(token: token_attributes.pluck(:token)).pluck(:token, :id).to_h
    end

    # Add StreamToken ids into upsert attributes so there is a unique attribute and a unique index isn't needed on token
    token_attributes.each do |attrs|
      # all attributes must be present for all items in upsert array
      attrs[:id] = existing_token_hash[attrs[:token]] if existing_token_hash[attrs[:token]].present?
    end

    result = token_attributes.present? ? StreamToken.upsert_all(token_attributes) : []

    # Fetch StreamToken fresh so they can be put into session and returned
    tokens = StreamToken.where(id: result.to_a.pluck("id"))
    session[:hash_tokens] += tokens.pluck(:token)
    session[:hash_tokens].uniq! # Avoid duplicate entry
    tokens.to_a
  end

  def self.logout!(session)
    session[:hash_tokens].each do |sha|
      where(token: sha).find_each(&:delete)
    end unless session[:hash_tokens].nil?
  end

  def self.purge_expired!(session)
    purged = expired.delete_all
    session[:hash_tokens] = StreamToken.where(token: Array(session[:hash_tokens])).order(expires: :desc).limit(max_tokens_per_user).pluck(:token)
    purged
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
