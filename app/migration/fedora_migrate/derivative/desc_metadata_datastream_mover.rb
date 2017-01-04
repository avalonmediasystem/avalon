module FedoraMigrate
  module Derivative
    class DescMetadataDatastreamMover < FedoraMigrate::SimpleXmlDatastreamMover

      def fields_to_copy
        %w(location_url hls_url duration track_id hls_track_id managed)
      end

      def migrate
        super
      end
    end
  end
end
