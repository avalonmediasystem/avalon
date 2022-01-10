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
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze

      def migrate_datastreams
        migrate_desc_metadata
        migrate_dublin_core
        # Make sure to migrate permissions before any of the other rights
        # datastreams since it creates the permissions report
        migrate_permissions
        migrate_inherited_rights
        migrate_default_rights
        # migrate_dates #skip because it doesn't do anything for us
        save
        migrate_relationships
        # super
      end

      def migrate_desc_metadata
        return unless source.datastreams.keys.include?(DESC_METADATA_DATASTREAM)
        mover = FedoraMigrate::AdminCollection::DescMetadataDatastreamMover.new(source.datastreams[DESC_METADATA_DATASTREAM], target)
        mover.migrate
        # report.descMetadata = mover.migrate
      end

      def migrate_default_rights
        return unless source.datastreams.keys.include?('defaultRights')
        mover = FedoraMigrate::AdminCollection::DefaultRightsDatastreamMover.new(source.datastreams['defaultRights'], target)
        mover.migrate
        report.permissions += mover.migrate
      end

      def self.wipeout!(collection)
        collection.default_permissions.destroy_all
        super
      end

      def self.empty?(collection)
        collection.default_permissions.blank? && super
      end
    end
  end
end
