module FedoraMigrate
  module MediaObject
    class DisplayMetadataDatastreamMover < FedoraMigrate::SimpleXmlDatastreamMover

      def migrate
        copy_field('duration', &:to_i)
        copy_field('avalon_resource_type', nil, true)
      end
    end
  end
end
