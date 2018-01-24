# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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

module Avalon
  class Intercom

    def self.avalons
      Settings.intercom
    end

    def initialize(user, avalon = "default")
      @user = user
      @avalon = avalons[avalon].symbolize_keys!
      @user_collections = nil
    end

    def user_collections
      @user_collections ||= get_user_collections
    end

    def push_media_object(media_object, collection_id)
      return [] unless @avalon.present?
      uri = URI.join(@avalon[:url], 'media_objects.json')
      payload = media_object.to_ingest_api_hash
      payload[:collection_id] = collection_id
      payload[:import_bib_record] = @avalon[:import_bib_record]
      payload[:publish] = @avalon[:publish]
      resp = RestClient::Request.execute(
        method: :post,
        url: uri.to_s,
        payload: payload.to_json,
        headers: { content_type: :json, accept: :json, :'Avalon-Api-Key' => @avalon[:api_token] },
        verify_ssl: false
      )
      result = JSON.parse(resp.body)
      result['id'].present? ? URI.join(Avalon::Intercom.avalons['default']['url'], 'media_objects/', result['id']) : result
    end
  end

  private

  def get_user_collections
    return [] unless @avalon.present?
    uri = URI.join(@avalon[:url], 'admin/collections.json')
    uri.query = "user=#{@user}"
    resp = RestClient::Request.execute(
      method: :get,
      url: uri.to_s,
      timeout: nil,
      open_timeout: nil,
      headers: { content_type: :json, accept: :json, :'Avalon-Api-Key' => target[:api_token] },
      verify_ssl: false
    )
    JSON.parse(resp.body)
  end

end
