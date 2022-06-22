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

module Avalon
  class Intercom
    attr_accessor :avalon

    def initialize(user, avalon = 'default')
      @user = user
      @avalon = Settings.intercom[avalon]
      @collections = nil
    end

    def user_collections(reload = false)
      if reload || @collections.nil?
        @collections = fetch_user_collections
      end
      @collections
    end

    def collection_valid?(collection)
      user_collections.any? { |c| c['id'] == collection }
    end

    def push_media_object(media_object, collection_id, include_structure = true)
      return { message: 'Avalon intercom target is not configured.' } unless @avalon.present?
      return { message: 'You are not authorized to push to this collection.' } unless collection_valid? collection_id
      begin
        resp = RestClient::Request.execute(
          method: :post,
          url: Addressable::URI.join(@avalon['url'], 'media_objects.json').to_s,
          payload: build_payload(media_object, collection_id, include_structure),
          headers: { content_type: :json, accept: :json, :'Avalon-Api-Key' => @avalon['api_token'] },
          verify_ssl: false,
          timeout: 3600
        )
        { link: Addressable::URI.join(@avalon['url'], 'media_objects/', JSON.parse(resp.body)['id']).to_s }
      rescue StandardError => e
        { message: e.message, status: e.respond_to?(:response) && e.response.present? ? e.response.code : 500 }
      end
    end

    private

      def build_payload(media_object, collection_id, include_structure)
        payload = media_object.to_ingest_api_hash(include_structure, remove_identifiers: @avalon['remove_identifiers'], publish: @avalon['publish'])
        payload[:collection_id] = collection_id
        payload[:import_bib_record] = @avalon['import_bib_record']
        payload[:publish] = @avalon['publish']
        payload.to_json
      end

      def fetch_user_collections
        return [] unless @avalon.present?
        uri = Addressable::URI.join(@avalon['url'], 'admin/collections.json')
        uri.query = "user=#{@user}&per_page=#{Integer::EXABYTE}"
        resp = RestClient::Request.execute(
          method: :get,
          url: uri.to_s,
          timeout: nil,
          open_timeout: nil,
          headers: { content_type: :json, accept: :json, :'Avalon-Api-Key' => @avalon['api_token'] },
          verify_ssl: false
        )
        JSON.parse(resp.body).map { |c| c.slice('id', 'name') }.sort_by { |c| c["name"] }
      end
  end
end
