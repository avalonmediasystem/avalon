module FedoraMigrate
  module Lease
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze

      def migrate
        #find mediaobject pid to see if it's already failed
        media_object_pids = FedoraMigrate.source.connection.find_by_sparql("SELECT ?pid FROM <#ri> WHERE { ?pid <http://projecthydra.org/ns/relations#isGovernedBy> <#{source.uri}> }").collect(&:pid)
        raise FedoraMigrate::Errors::MigrationError, "Parent media object(s) (#{media_object_pids}) failed to migrate" if media_object_pids.all? {|mo_pid| MigrationStatus.where(f3_pid: mo_pid).first.status == "failed" }
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
