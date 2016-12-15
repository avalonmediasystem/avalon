module FedoraMigrate
  module MediaObject
    class DublinCoreDatastreamMover < FedoraMigrate::DublinCoreDatastreamMover

      def migrate
        target.avalon_uploader = dc.xpath('//creator').text
        target.avalon_publisher = dc.xpath('//publisher').text
        super
      end
    end
  end
end
