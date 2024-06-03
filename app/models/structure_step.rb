# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

  class StructureStep < Avalon::Workflow::BasicStep
    def initialize(step = 'structure', title = "Structure", summary = "Organization of resources", template = 'structure')
      super
    end

    def execute context
      media_object = context[:media_object]
      if ! context[:master_file_ids].nil?
        media_object.section_ids = context[:master_file_ids]
        media_object.save
      end
      context
    end
  end
