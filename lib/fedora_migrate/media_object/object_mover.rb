require 'fedora_migrate/reassign_id_object_mover'

module FedoraMigrate
  module MediaObject
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze
      WORKFLOW_DATASTREAM = "workflow".freeze

      def migrate_datastreams
        migrate_dublin_core
        migrate_relationships
        migrate_permissions
        migrate_desc_metadata #Need to do this after target is saved
        migrate_workflow
        # migrate_dates #skip because it doesn't do anything for us
        save
        # super
      end

      def migrate_desc_metadata
        return unless source.datastreams.keys.include?(DESC_METADATA_DATASTREAM)
        mover = FedoraMigrate::DatastreamMover.new(source.datastreams[DESC_METADATA_DATASTREAM], target.attached_files[DESC_METADATA_DATASTREAM], options)
        #FIXME change MODS recordIdentifier to be new fedora noid id
        report.content_datastreams << ContentDatastreamReport.new(target.attached_files[DESC_METADATA_DATASTREAM], mover.migrate)
      end

      def migrate_workflow
        return unless source.datastreams.keys.include?(WORKFLOW_DATASTREAM)
        FedoraMigrate::DatastreamMover.new(source.datastreams[WORKFLOW_DATASTREAM], target.workflow).migrate
      end
    end
  end
end
