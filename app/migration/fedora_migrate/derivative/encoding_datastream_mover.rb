# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

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
        resolution = present_or_nil(encodingProfile.xpath('//video/resolution').text)
        res_width,res_height = resolution.present? ? resolution.split('x') : [nil,nil]
        width = present_or_nil(encodingProfile.xpath('//video/resolution/width').text)
        height = present_or_nil(encodingProfile.xpath('//video/resolution/height').text)
        if (res_width.present? and width.present? and res_width!=width) or (res_height.present? and height.present? and res_height!=height)
          raise FedoraMigrate::Errors::MigrationError, "Derivative resolution and height/width do not match" 
        end
        target.width = width || res_width
        target.height = height || res_height
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
