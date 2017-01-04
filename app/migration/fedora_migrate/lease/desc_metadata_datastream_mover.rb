module FedoraMigrate
  module Lease
    class DescMetadataDatastreamMover < FedoraMigrate::SimpleXmlDatastreamMover

      def fields_to_copy
        %w(begin_time end_time)
      end

    end
  end
end
