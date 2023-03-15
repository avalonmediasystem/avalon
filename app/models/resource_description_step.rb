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

class ResourceDescriptionStep < Avalon::Workflow::BasicStep
  def initialize(step = 'resource-description', title = "Resource description", summary = "Metadata about the item", template = 'resource_description')
    super
  end

  def execute context
    media_object = context[:media_object]
    populate_from_catalog = context[:media_object_params].delete(:import_bib_record)
    if populate_from_catalog && context[:media_object_params][:bibliographic_id].present? && Avalon::BibRetriever.configured?(context[:media_object_params][:bibliographic_id][:source])
      media_object.descMetadata.populate_from_catalog!(context[:media_object_params][:bibliographic_id][:id],context[:media_object_params][:bibliographic_id][:source])
    else
      media_object.permalink = context[:media_object_params].delete(:permalink)
      media_object.update_attributes(context[:media_object_params])
    end
    media_object.save
    context
  end
end
