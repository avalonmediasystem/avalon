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

require 'zoom'

module Avalon
  class BibRetriever
    class Zoom < ::Avalon::BibRetriever

      def initialize config
        super
        @config['port'] ||= 7090
        @config['attribute'] ||= 7
      end

      def get_record(bib_id)
        record = nil
        ZOOM::Connection.open(config['host'], config['port']) do |conn|
          conn.database_name = config['database']
          conn.preferred_record_syntax = 'marc21'
          record = conn.search("@attr 1=#{config['attribute']} #{bib_id}")
        end
        record[0].nil? ? nil : marc2mods(record[0].raw)
      end
    end
  end
end
