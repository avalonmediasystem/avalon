# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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
  class BibRetriever
    class SRU < ::Avalon::BibRetriever
      def get_record(bib_id)
        doc = Nokogiri::XML RestClient.get(url_for(bib_id))
        record = doc.xpath('//zs:recordData/*', "zs"=>"http://www.loc.gov/zing/srw/").first
        record.nil? ? nil : marcxml2mods(record.to_s)
      end
      
      def url_for(bib_id)
        uri = URI.parse config['url']
        uri.query = "version=1.1&operation=searchRetrieve&maximumRecords=10000&recordSchema=marcxml&query=rec.id=#{bib_id}"
        uri.to_s
      end
    end
  end
end
