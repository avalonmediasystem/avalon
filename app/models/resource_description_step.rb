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

class ResourceDescriptionStep < Avalon::Workflow::BasicStep
  def initialize(step = 'resource-description', title = "Resource description", summary = "Metadata about the item", template = 'resource_description')
    super
  end

  def execute context
    mediaobject = context[:mediaobject]
    populate_from_catalog = context[:media_object][:import_bib_record].present?
    if populate_from_catalog and Avalon::BibRetriever.configured?
      mediaobject.descMetadata.populate_from_catalog!(context[:media_object][:bibliographic_id],context[:media_object][:bibliographic_id_label])
    else
      mediaobject.permalink = context[:media_object].delete(:permalink)
      mediaobject.update_datastream(:descMetadata, context[:media_object])
    end
    mediaobject.save
    context
  end
end
