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
# require 'rest-client'

module Avalon
  class Intercom
    @path = Rails.root.join(Settings.intercom.path) if Settings.intercom

    def self.avalons
      avalons = {}
      if File.file?(@path)
        yaml = YAML.safe_load(File.read(@path))
        avalons = yaml if yaml.present?
      end
      avalons
    end

    def self.user_collections(user, avalon = "default")
      target = avalons[avalon]
      return [] unless target.present?
      target.symbolize_keys!
      uri = URI.join(target[:url], 'admin/collections.json')
      uri.query = "user=#{user}"
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

    def self.push_media_object(media_object, collection_id, avalon = "default")
      target = avalons[avalon].symbolize_keys
      uri = URI.join(target[:url], 'media_objects.json')
      payload = media_object.to_ingest_api_hash
      payload[:collection_id] = collection_id
      payload[:import_bib_record] = target[:import_bib_record]
      payload[:publish] = target[:publish]
      resp = RestClient::Request.execute(
        method: :post,
        url: uri.to_s,
        payload: payload.to_json,
        headers: { content_type: :json, accept: :json, :'Avalon-Api-Key' => target[:api_token] },
        verify_ssl: false
      )
      JSON.parse(resp.body)
    end
  end
end
