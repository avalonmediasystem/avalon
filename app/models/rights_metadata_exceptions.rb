# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

module RightsMetadataExceptions
  def self.apply_to(mod)
    mod.class_eval do
      unless self == Hydra::Datastream::RightsMetadata
        include OM::XML::Document
        use_terminology(Hydra::Datastream::RightsMetadata) 
      end
      extend_terminology do |t|
        t.exceptions_access(:ref=>[:access], :attributes=>{:type=>"exceptions"})
      end

      # @param [Symbol] type (either :group or :person)
      # @return 
      # This method limits the response to known access levels.  Probably runs a bit faster than .permissions().
      def quick_search_by_type(type)
        result = {}
        [{:discover_access=>"discover"},{:read_access=>"read"},{:edit_access=>"edit"},{:exceptions_access=>"exceptions"}].each do |access_levels_hash|
          access_level = access_levels_hash.keys.first
          access_level_name = access_levels_hash.values.first
          self.find_by_terms(*[access_level, type]).each do |entry|
            result[entry.text] = access_level_name
          end
        end
        return result
      end
    end
  end
end
