module FedoraMigrate
  class DublinCoreDatastreamMover < Mover

    attr_accessor :dc

    def post_initialize
      @dc = xml_from_content
      dc.remove_namespaces!
    end

    def migrate
      target.identifier += dc.xpath('//identifier').map(&:text)
      target.identifier += [source.pid]
      super
    end

    private

      def xml_from_content
        Nokogiri::XML(source.content)
      end
  end
end
