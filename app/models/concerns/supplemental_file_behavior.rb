# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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
module SupplementalFileBehavior
  extend ActiveSupport::Concern

  included do |base|
    property :supplemental_files_json, predicate: Avalon::RDFVocab.const_get(base.name).supplementalFiles, multiple: false do |index|
      index.as :stored_sortable
    end
  end

  # FIXME: Switch absolute_path to stored_file_id and use valkyrie or other file store to allow for abstracting file path and content from fedora (think stream urls)
  # See https://github.com/samvera/valkyrie/blob/master/lib/valkyrie/storage/disk.rb
  # SupplementalFile = Struct.new(:id, :label, :absolute_path, keyword_init: true)

  # @return [SupplementalFile]
  def supplemental_files
    return [] if supplemental_files_json.blank?
    JSON.parse(supplemental_files_json).collect { |file_gid| GlobalID::Locator.locate(file_gid) }
  end

  # @param files [SupplementalFile]
  def supplemental_files=(files)
    self.supplemental_files_json = files.collect { |file| file.to_global_id.to_s }.to_s
  end
end
