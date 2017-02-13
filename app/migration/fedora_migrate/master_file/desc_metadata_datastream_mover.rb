module FedoraMigrate
  module MasterFile
    class DescMetadataDatastreamMover < FedoraMigrate::SimpleXmlDatastreamMover

      def fields_to_copy
        %w(file_checksum file_size duration display_aspect_ratio original_frame_size date_digitized physical_description file_location file_format)
      end

      def migrate
        super
        ['poster_offset','thumbnail_offset'].each do |field|
          copy_field(field, &:to_i)
        end
      end
    end
  end
end
