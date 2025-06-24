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

# frozen_string_literal: true
module SupplementalFileReadBehavior
  extend ActiveSupport::Concern

  def reload
    @supplemental_files = nil
    super
  end

  # @return [SupplementalFile]
  def supplemental_files(tag: '*')
    return [] if supplemental_files_json.blank?
    # If the supplemental_files_json becomes out of sync with the
    # database after a delete, this check could fail. Have not
    # encountered in a live environment but came up in automated
    # testing. Adding a rescue on fail to locate allows us to skip
    # these out of sync files.
    @supplemental_files ||= begin
                              GlobalID::Locator.locate_many(JSON.parse(supplemental_files_json))
                            rescue ActiveRecord::RecordNotFound
                              nil
                            end.compact
    return [] if @supplemental_files.blank?

    case tag
    when '*'
      @supplemental_files
    when nil
      @supplemental_files.select { |file| file.tags.empty? }
    else
      @supplemental_files.select { |file| Array(tag).all? { |t| file.tags.include?(t) } }
    end
  end
end
