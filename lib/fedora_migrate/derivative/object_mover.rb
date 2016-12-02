require 'fedora_migrate/reassign_id_object_mover'
require 'fedora_migrate/derivative/desc_metadata_datastream_mover'
require 'fedora_migrate/derivative/encoding_datastream_mover'
require 'pry'

module FedoraMigrate
  module Derivative
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze
      DERIVATIVE_DATASTREAM = "derivativeFile".freeze
      ENCODING_DATASTREAM = "encoding".freeze

      def migrate_datastreams
        migrate_desc_metadata
        migrate_file_location
        migrate_transcoding_metadata
        migrate_relationships
        save
        # super
      end

      def migrate_desc_metadata
        return unless source.datastreams.keys.include?(DESC_METADATA_DATASTREAM)
        mover = FedoraMigrate::Derivative::DescMetadataDatastreamMover.new(source.datastreams[DESC_METADATA_DATASTREAM], target)
        mover.migrate
        # report.descMetadata = mover.migrate
      end

      def migrate_transcoding_metadata
        return unless source.datastreams.keys.include?(ENCODING_DATASTREAM)
        mover = FedoraMigrate::Derivative::EncodingDatastreamMover.new(source.datastreams[ENCODING_DATASTREAM], target)
        mover.migrate
      end

      def migrate_file_location
        return unless source.datastreams.keys.include?(DERIVATIVE_DATASTREAM)
        target.derivativeFile = source.datastreams[DERIVATIVE_DATASTREAM].content
      end

    end
  end
end
