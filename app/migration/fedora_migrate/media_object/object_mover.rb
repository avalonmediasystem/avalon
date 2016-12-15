require 'ostruct'

module FedoraMigrate
  module MediaObject
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze
      WORKFLOW_DATASTREAM = "workflow".freeze
      DISPLAY_METADATA_DATASTREAM = "displayMetadata".freeze

      def migrate_datastreams
        migrate_dublin_core
        migrate_relationships
        migrate_permissions
        migrate_desc_metadata #Need to do this after target is saved
        migrate_workflow
        migrate_display_metadata
        # migrate_dates #skip because it doesn't do anything for us
        save
        # super
      end

      def migrate_dublin_core
        return unless source.datastreams.keys.include?('DC')
        mover = FedoraMigrate::MediaObject::DublinCoreDatastreamMover.new(source.datastreams['DC'], target)
        mover.migrate
        # report.dc = mover.migrate
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

      def migrate_display_metadata
        return unless source.datastreams.keys.include?(DISPLAY_METADATA_DATASTREAM)
        FedoraMigrate::MediaObject::DisplayMetadataDatastreamMover.new(source.datastreams[DISPLAY_METADATA_DATASTREAM], target).migrate
      end

      def second_pass
        @report = OpenStruct.new(options[:report]) if options[:report].present?
        mover = FedoraMigrate::MediaObject::MasterFileAggregationMover.new(source, target)
        report.master_file_order = mover.migrate
        report
      end
    end
  end
end
