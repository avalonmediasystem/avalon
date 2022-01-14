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
  module AdminCollection
    class DescMetadataDatastreamMover < FedoraMigrate::SimpleXmlDatastreamMover

      def fields_to_copy
        %w(name unit description dropbox_directory_name)
      end
      
      def migrate
        super
        add_unit_to_controlled_vocabulary(target.unit)
      end

      private

      def add_unit_to_controlled_vocabulary(unit)
        v = Avalon::ControlledVocabulary.vocabulary
        unless v[:units].include? unit
         v[:units] |= Array(unit)
         Avalon::ControlledVocabulary.vocabulary = v
        end
      end
    end
  end
end
