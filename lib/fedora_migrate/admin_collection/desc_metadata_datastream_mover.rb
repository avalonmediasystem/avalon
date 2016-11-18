module FedoraMigrate
  module AdminCollection
    class DescMetadataDatastreamMover < FedoraMigrate::Mover

      attr_accessor :descMetadata

      def post_initialize
        @descMetadata = xml_from_content
      end

      def migrate
        target.name = @descMetadata.xpath('fields/name').text
        target.unit = @descMetadata.xpath('fields/unit').text
        add_unit_to_controlled_vocabulary(target.unit)
        description = @descMetadata.xpath('fields/description').text
        target.description = description unless description.empty?
        dropbox_dir_name = @descMetadata.xpath('fields/dropbox_directory_name').text
        target.dropbox_directory_name = dropbox_dir_name unless dropbox_dir_name.empty?
        super
      end

      private

        def add_unit_to_controlled_vocabulary(unit)
          v = Avalon::ControlledVocabulary.vocabulary
          unless v[:units].include? unit
           v[:units] |= Array(unit)
           Avalon::ControlledVocabulary.vocabulary = v
          end
        end

        def xml_from_content
          Nokogiri::XML(source.content)
        end
    end
  end
end
