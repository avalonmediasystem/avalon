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

    def initialize(user, avalon = 'default')
      @user = user
      @avalon = Settings.intercom[avalon]
      @user_collections = nil
    end

    def user_collections
      @user_collections ||= get_user_collections
    end

    def push_media_object(media_object, collection_id, include_structure = true)
      return [] unless @avalon.present?
      uri = URI.join(@avalon[:url], 'media_objects.json')
      payload = media_object.to_ingest_api_hash(include_structure)
      payload[:collection_id] = collection_id
      payload[:import_bib_record] = @avalon[:import_bib_record]
      payload[:publish] = @avalon[:publish]
      begin
        resp = RestClient::Request.execute(
          method: :post,
          url: uri.to_s,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json, :'Avalon-Api-Key' => @avalon[:api_token] },
          verify_ssl: false
        )
        result = { link: URI.join(@avalon[:url], 'media_objects/', JSON.parse(resp.body)['id']).to_s }
      rescue StandardError => e
        result = { status: e.response.code, message: e.message }
      end
      result
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
        headers: { content_type: :json, accept: :json, :'Avalon-Api-Key' => @avalon[:api_token] },
        verify_ssl: false
      )
      JSON.parse(resp.body).map{ |c| c.slice('id', 'name') }.sort_by{ |c| c["name"] }
    end
  end

end
