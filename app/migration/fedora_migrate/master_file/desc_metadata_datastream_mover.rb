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

module FedoraMigrate
  module MasterFile
    class DescMetadataDatastreamMover < FedoraMigrate::SimpleXmlDatastreamMover

      def fields_to_copy
        %w(file_checksum file_size duration display_aspect_ratio original_frame_size date_digitized physical_description file_location file_format)
      end

      def migrate
        super
        ['poster_offset','thumbnail_offset'].each do |field|
          copy_field(field, &:to_i)
        end
      end
    end
  end
end
