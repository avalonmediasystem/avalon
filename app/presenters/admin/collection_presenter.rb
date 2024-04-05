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

class Admin::CollectionPresenter
  attr_reader :document

  def initialize(solr_doc, media_object_count: nil, unpublished_media_object_count: nil)
    @document = solr_doc
    @media_object_count = media_object_count
    @unpublished_media_object_count = unpublished_media_object_count
  end

  delegate :id, to: :document

  def name
    document["name_ssi"]
  end

  def unit
    document["unit_ssi"]
  end

  def description
    document["description_tesim"]&.first
  end

  def media_object_count
    @media_object_count ||= MediaObject.where("collection_ssim" => name).count
  end

  def unpublished_media_object_count
    @unpublished_media_object_count ||= MediaObject.where("collection_ssim" => name, 'workflow_published_sim' => "Unpublished").count
  end

  def managers
    @managers ||= document["edit_access_person_ssim"] & (document["collection_managers_ssim"] || [])
  end

  def editors
    @editors ||= document["edit_access_person_ssim"] - managers
  end

  def depositors
    document["read_access_person_ssim"]
  end

  def manager_count
    managers.size
  end

  def as_json(_)
    total_count = media_object_count
    unpub_count = unpublished_media_object_count
    pub_count = total_count - unpub_count

    {
      id: id,
      name: name,
      unit: unit,
      description: description,
      object_count: {
        total: total_count,
        published: pub_count,
        unpublished: unpub_count
      },
      roles: {
        managers: managers,
        editors: editors,
        depositors: depositors
      }
    }
  end
end
