module FedoraMigrate
  module MasterFile
    class MhMetadataDatastreamMover < FedoraMigrate::SimpleXmlDatastreamMover
      def fields_to_copy
        %w(workflow_id workflow_name percent_complete percent_succeeded percent_failed status_code operation error encoder_classname)
      end
    end
  end
end
