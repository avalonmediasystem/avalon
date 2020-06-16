# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

# A tool for mapping from a variations id to an Avalon object
# @since 5.1.0
module Avalon
  # A tool for mapping from a variations id to an Avalon object
  class VariationsMappingService
    MEDIA_OBJECT_ID_MAP = YAML.load_file(Settings.variations.media_object_id_map_file).freeze rescue {}
    TIMELINE_MAP = YAML.load_file(Settings.variations.timeliner_map_file).freeze rescue {}

    def find_master_file(variations_media_object_id)
      raise ArgumentError, 'Not a valid Variations Media Object ID' unless variations_media_object_id.match?(/MediaObject/)
      notis_id = MEDIA_OBJECT_ID_MAP[variations_media_object_id]
      raise "Unknown Variations Id: #{variations_media_object_id}" unless notis_id
      master_file = MasterFile.where(identifier_ssim: notis_id.downcase).first
      raise "MasterFile could not be found for Variations label #{notis_id}" unless master_file
      master_file
    end

    def find_offset_master_file(variations_container_id, media_offset)
      raise ArgumentError, 'Not a valid Variations Container ID' unless variations_container_id.match?(/Container/)
      container = TIMELINE_MAP[variations_container_id]
      raise "Unknown Variations Container: #{variations_container_id}" unless container.present?
      notis_id = nil
      container_start = 0

      container.each do |master_file|
        container_start = master_file[:offset].to_i
        container_end = container_start + master_file[:duration].to_i
        if container_start <= media_offset && media_offset < container_end
          notis_id = master_file[:id]
          break
        end
      end

      raise "Invalid offset for container: #{variations_container_id} #{media_offset}" unless notis_id
      master_file = MasterFile.where(identifier_ssim: notis_id.downcase).first
      raise "MasterFile could not be found for Variations label #{notis_id}" unless master_file
      [master_file, container_start]
    end
  end
end
