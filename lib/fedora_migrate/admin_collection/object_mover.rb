require 'fedora_migrate/reassign_id_object_mover'
require 'fedora_migrate/admin_collection/desc_metadata_datastream_mover'
require 'fedora_migrate/admin_collection/default_rights_datastream_mover'

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
    end
  end
end
