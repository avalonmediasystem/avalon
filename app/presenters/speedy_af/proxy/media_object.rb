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

class SpeedyAF::Proxy::MediaObject < SpeedyAF::Base
  def to_model
    self
  end

  def persisted?
    id.present?
  end

  def model_name
    ActiveModel::Name.new(MediaObject)
  end

  def to_param
    id
  end

  # @return [SupplementalFile]
  def supplemental_files(tag: '*')
    return [] if supplemental_files_json.blank?
    files = JSON.parse(supplemental_files_json).collect { |file_gid| GlobalID::Locator.locate(file_gid) }
    case tag
    when '*'
      files
    when nil
      files.select { |file| file.tags.empty? }
    else
      files.select { |file| Array(tag).all? { |t| file.tags.include?(t) } }
    end
  end
end
