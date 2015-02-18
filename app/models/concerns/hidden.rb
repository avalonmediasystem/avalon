# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
  module AccessControls
    module Hidden
      extend ActiveSupport::Concern

      def hidden= value
        groups = self.discover_groups
        if value
          groups += ["nobody"]
        else
          groups -= ["nobody"]
        end
        self.discover_groups = groups.uniq
      end

      def hidden?
        self.discover_groups.include? "nobody"
      end

      def to_solr(solr_doc = Hash.new, opts = {})
        solr_doc[Solrizer.default_field_mapper.solr_name("hidden", type: :boolean)] = hidden?
        super(solr_doc, opts)
      end
    end
  end
end
