# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

class Admin::UnitPresenter
  attr_reader :document

  def initialize(solr_doc, collection_count: nil)
    @document = solr_doc
    @collection_count = collection_count
  end

  delegate :id, to: :document

  def name
    document["name_ssi"]
  end

  def description
    document["description_tesim"]&.first
  end

  def collection_count
    @collection_count ||= Admin::Collection.where("unit_ssi" => name).count
  end

  def managers
    @managers ||= Array(document["edit_access_person_ssim"]) & Array(document["unit_administrators_ssim"])
  end

  def editors
    @editors ||= Array(document["edit_access_person_ssim"]) - managers
  end

  def depositors
    Array(document["read_access_person_ssim"])
  end

  def manager_count
    managers.size
  end

  def as_json(_)
    {
      id: id,
      name: name,
      description: description,
      object_count: {
        total: collection_count
      },
      roles: {
        managers: managers,
        editors: editors
      }
    }
  end
end
