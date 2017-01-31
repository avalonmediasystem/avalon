module FedoraMigrate
  module Derivative
    class ObjectMover < ReassignIdObjectMover
      DESC_METADATA_DATASTREAM = "descMetadata".freeze
      DERIVATIVE_DATASTREAM = "derivativeFile".freeze
      ENCODING_DATASTREAM = "encoding".freeze

      def migrate
        #find master file pid to see if it's already failed
        rels_rdf = RDF::Graph.new { |g| g.from_rdfxml(source.datastreams["RELS-EXT"].content) }
        master_file_pid = rels_rdf.statements.find {|s| s.predicate == ActiveFedora::RDF::Fcrepo::RelsExt.isDerivationOf }.object.to_s.split('/').last
        mf_status = MigrationStatus.where(f3_pid: master_file_pid).first.status
        raise FedoraMigrate::Errors::MigrationError, "Parent master file (#{master_file_pid}) failed to migrate" if mf_status == "failed"
        super
      end

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
