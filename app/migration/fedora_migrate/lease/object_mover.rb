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
  module Lease
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze

      def migrate
        #find mediaobject pid to see if it's already failed
#        media_object_pids = FedoraMigrate.source.connection.find_by_sparql("SELECT ?pid FROM <#ri> WHERE { ?pid <http://projecthydra.org/ns/relations#isGovernedBy> <#{source.uri}> }").collect(&:pid)
#        raise FedoraMigrate::Errors::MigrationError, "Parent media object(s) (#{media_object_pids}) failed to migrate" if media_object_pids.all? {|mo_pid| MigrationStatus.where(f3_pid: mo_pid).first.status == "failed" }
        super
      end

      def migrate_datastreams
        migrate_desc_metadata
        migrate_permissions
        migrate_inherited_rights
        save
        migrate_relationships
      end

      def migrate_desc_metadata
        return unless source.datastreams.keys.include?(DESC_METADATA_DATASTREAM)
        mover = FedoraMigrate::Lease::DescMetadataDatastreamMover.new(source.datastreams[DESC_METADATA_DATASTREAM], target)
        mover.migrate
        # report.descMetadata = mover.migrate
      end
    end
  end
end
