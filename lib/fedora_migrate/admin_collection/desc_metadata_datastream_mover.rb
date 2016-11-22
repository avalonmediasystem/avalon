module FedoraMigrate
  module AdminCollection
    class DescMetadataDatastreamMover < FedoraMigrate::SimpleXmlDatastreamMover

      def fields_to_copy
        %w(name unit description dropbox_directory_name)
      end
      
      def migrate
        super
        add_unit_to_controlled_vocabulary(target.unit)
      end

      private

      def add_unit_to_controlled_vocabulary(unit)
        v = Avalon::ControlledVocabulary.vocabulary
        unless v[:units].include? unit
         v[:units] |= Array(unit)
         Avalon::ControlledVocabulary.vocabulary = v
        end
      end
    end
  end
end
