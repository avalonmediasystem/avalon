require 'fedora_migrate/reassign_id_object_mover'
require 'fedora_migrate/master_file/desc_metadata_datastream_mover'
require 'fedora_migrate/master_file/mh_metadata_datastream_mover'
require 'pry'

module FedoraMigrate
  module MasterFile
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze
      POSTER_DATASTREAM = "poster".freeze
      THUMBNAIL_DATASTREAM = "thumbnail".freeze
      STRUCTURAL_METADATA_DATASTREAM = "structuralMetadata".freeze
      CAPTIONS_DATASTREAM = "captions".freeze
      MASTERFILE_DATASTREAM = "masterFile".freeze
      MH_METADATA_DATASTREAM = "mhMetadata".freeze

      def migrate_datastreams
        migrate_dublin_core
        migrate_desc_metadata
        migrate_file_location
        migrate_transcoding_metadata
        migrate_poster_and_thumbnail
        migrate_structural_metadata
        migrate_captions
        migrate_relationships
        save
        # super
      end

      def migrate_desc_metadata
        return unless source.datastreams.keys.include?(DESC_METADATA_DATASTREAM)
        mover = FedoraMigrate::MasterFile::DescMetadataDatastreamMover.new(source.datastreams[DESC_METADATA_DATASTREAM], target)
        mover.migrate
        # report.descMetadata = mover.migrate
      end

      def migrate_transcoding_metadata
        return unless source.datastreams.keys.include?(MH_METADATA_DATASTREAM)
        mover = FedoraMigrate::MasterFile::MhMetadataDatastreamMover.new(source.datastreams[MH_METADATA_DATASTREAM], target)
        mover.migrate
      end

      def migrate_poster_and_thumbnail
        migrate_content_datastream(POSTER_DATASTREAM)
        migrate_content_datastream(THUMBNAIL_DATASTREAM)
      end

      def migrate_structural_metadata
        return unless source.datastreams.keys.include?(STRUCTURAL_METADATA_DATASTREAM)
        FedoraMigrate::DatastreamMover.new(source.datastreams[STRUCTURAL_METADATA_DATASTREAM], target.structuralMetadata).migrate
      end

      def migrate_captions
        migrate_content_datastream(CAPTIONS_DATASTREAM)
      end

      def migrate_file_location
        return unless source.datastreams.keys.include?(MASTERFILE_DATASTREAM)
        target.masterFile = source.datastreams[MASTERFILE_DATASTREAM].content
      end

      private
      def migrate_content_datastream(ds_name)
        return unless source.datastreams.keys.include?(ds_name)
        mover = FedoraMigrate::DatastreamMover.new(source.datastreams[ds_name], target.thumbnail)
        mover.migrate
        #report.content_datastreams << ContentDatastreamReport.new(target.attached_files[ds_name], mover.migrate)
      end
    end
  end
end
