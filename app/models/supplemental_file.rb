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

class SupplementalFile < ApplicationRecord
  has_one_attached :file

  # TODO: the empty tag should represent a generic supplemental file
  validates :tags, array_inclusion: ['transcript', 'caption', 'machine_generated', '', nil]

  serialize :tags, Array

  def attach_file(new_file)
    file.attach(new_file)
    self.label = file.filename.to_s if label.blank?
  end

  def machine_generated?
    tags.include?('machine_generated')
  end
end
