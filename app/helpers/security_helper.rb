# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

module SecurityHelper
  include CdlHelper

  def add_stream_cookies(stream_info)
    SecurityHandler.secure_cookies(target: stream_info[:id], request_host: request.server_name).each_pair do |name, value|
      cookies[name] = value
    end
  end

  def secure_streams(stream_info, media_object_id)
    add_stream_url(stream_info) unless not_checked_out?(media_object_id)
    stream_info
  end

  # Batch version of secure_streams
  # media_object CDL check only happens once
  # session tokens retrieved in batch then passed into add_stream_url
  # Returns Hash[MasterFile.id, stream_info]
  def secure_stream_infos(master_files, media_object_id)
    stream_info_hash = {}
    if not_checked_out?(media_object_id)
      master_files.each { |mf| stream_info_hash[mf.id] = mf.stream_details }
    else
      stream_tokens = StreamToken.get_session_tokens_for(session: session, targets: master_files.map(&:id))
      stream_token_hash = stream_tokens.pluck(:target, :token).to_h
      master_files.each { |mf| stream_info_hash[mf.id] = secure_stream_info(mf.stream_details, stream_token_hash[mf.id]) }
    end
    stream_info_hash
  end

  # Same as secure_streams except without CDL checking
  def secure_stream_info(stream_info, token)
    add_stream_url(stream_info, token: token)
    stream_info
  end

  # Optional token kwarg used if passed in
  def add_stream_url(stream_info, token: nil)
    add_stream_cookies(id: stream_info[:id])
    [:stream_hls].each do |protocol|
      stream_info[protocol].each do |quality|
        quality[:url] = SecurityHandler.secure_url(quality[:url], session: session, target: stream_info[:id], protocol: protocol, token: token)
      end
    end
  end

  private

    def not_checked_out?(media_object_id)
      lending_enabled?(SpeedyAF::Proxy::MediaObject.find(media_object_id)) && Checkout.checked_out_to_user(media_object_id, current_user&.id).empty?
    end
end
