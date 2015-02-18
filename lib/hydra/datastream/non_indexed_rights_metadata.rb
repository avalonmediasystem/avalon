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

require 'concerns/hidden'
require 'concerns/virtual_groups'

module Hydra
  module Datastream
    class NonIndexedRightsMetadata < Hydra::Datastream::RightsMetadata   
      include Hydra::AccessControls::Visibility 
      include Avalon::AccessControls::Hidden
      include Avalon::AccessControls::VirtualGroups

      def to_solr(solr_doc=Hash.new)
        return solr_doc
      end
    end
  end
end
