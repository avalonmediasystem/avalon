module FedoraMigrate
  module Lease
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze

      def migrate_datastreams
        migrate_dublin_core
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
