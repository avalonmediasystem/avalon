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

require 'rest-client'

module Avalon
  class BibRetriever
    class SRU < ::Avalon::BibRetriever
      def initialize config
        super
        @config['query'] ||= 'rec.id=%{bib_id}'
        @config['namespace'] ||= "http://www.loc.gov/zing/srw/"
      end
      
      def get_record(bib_id)
        # multiple queries specified as an Array in the config will run each in sequence until a record is found
        Array(config['query']).each do |query|
          doc = Nokogiri::XML RestClient.get(url_for(query, bib_id))
          record = doc.xpath('//zs:recordData/*', "zs"=>@config['namespace']).first
          return marcxml2mods(record.to_s) if record.present?
        end
        nil
      end
      
      def url_for(query, bib_id)
        uri = Addressable::URI.parse config['url']
        query_param = Addressable::URI.escape(query % { bib_id: bib_id.to_s })
        uri.query = "version=1.1&operation=searchRetrieve&maximumRecords=1&recordSchema=marcxml&query=#{query_param}"
        uri.to_s
      end
    end
  end
end
