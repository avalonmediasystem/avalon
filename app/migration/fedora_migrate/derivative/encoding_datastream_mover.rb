module FedoraMigrate
  module Derivative
    class EncodingDatastreamMover < Mover
      attr_accessor :encodingProfile

      def post_initialize
        @encodingProfile = xml_from_content
      end

      def migrate
        target.quality = present_or_nil(encodingProfile.xpath('//quality').text)
        target.mime_type = present_or_nil(encodingProfile.xpath('//mime_type').text)
        target.audio_bitrate = present_or_nil(encodingProfile.xpath('//audio/bitrate').text)
        target.audio_codec = present_or_nil(encodingProfile.xpath('//audio/codec').text)
        target.video_bitrate = present_or_nil(encodingProfile.xpath('//video/bitrate').text)
        target.video_codec = present_or_nil(encodingProfile.xpath('//video/codec').text)
        width = present_or_nil(encodingProfile.xpath('//video/resolution/width').text)
        height = present_or_nil(encodingProfile.xpath('//video/resolution/height').text)
        target.resolution = "#{width}x#{height}" if width.present? && height.present?
        super
      end

      private
      def xml_from_content
        Nokogiri::XML(source.content)
      end

      def present_or_nil(value)
        return nil unless value.present?
        value
      end

    end
  end
end
