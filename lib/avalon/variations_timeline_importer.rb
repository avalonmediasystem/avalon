# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

require 'avalon/variations_mapping_service'

# A tool for converting a variations v2t file to an Avalon timeline
# @since 6.5.0
module Avalon
  # Class for the conversion of a v2t file to an Avalon timeline
  class VariationsTimelineImporter
    DEFAULT_TIMELINE_TITLE = 'Imported Variations Timeline'
    @timepoint_index = 0

    # Parse and build the timeline, saving along the way
    def import_timeline(timeline_file, user)
      timeline_xml = parse_timeline(timeline_file)
      build_timeline(timeline_xml, user)
    end

    private

      # Takes a timeline and parses it using Nokogiri
      # @param [File] timeline The timeline xml file
      # @raise [ArgumentError] When the timeline cannot be parsed or is not a timeline file
      def parse_timeline(file)
        xml = nil
        begin
          xml = Nokogiri::XML(file, &:strict)
        rescue
          raise ArgumentError, 'File is not valid XML.'
        end
        raise ArgumentError, 'File is not a timeline' unless xml.xpath('//Timeline').first.present?
        xml
      end

      def build_timeline(timeline_xml, user)
        @timepoints ||= extract_timepoints(timeline_xml)

        timeline = initialize_timeline(timeline_xml, user)

        container = timeline_xml.xpath('//Timeline/@mediaContent').text
        media_offset = timeline_xml.xpath('//Timeline/@mediaOffset').text.to_i
        media_length = timeline_xml.xpath('//Timeline/@mediaLength').text.to_i

        mf, container_start = VariationsMappingService.new.find_offset_master_file(container, media_offset)

        starttime = (media_offset - container_start) / 1000.0
        endtime = (media_offset + media_length - container_start) / 1000.0
        timeline.source = Rails.application.routes.url_helpers.master_file_url(mf) + "?t=#{starttime},#{endtime}"

        timeline.save
        timeline.generate_manifest

        manifest = JSON.parse(timeline.manifest)
        bubbles = structures(timeline, timeline_xml.xpath('/Timeline/Bubble'))
        manifest['structures'] = bubbles.present? ? bubbles[:items] : []
        manifest['annotations'] = annotations(timeline, timeline_xml)
        manifest['tl:settings'] = { 'tl:backgroundColour': extract_background_color(timeline_xml) }
        timeline.manifest = manifest.to_json

        if timeline.invalid?
          errors = timeline.full_messages
          timeline.destroy
          raise 'Timeline to import was invalid: ' + errors.join(', ')
        end
        timeline.save
        timeline
      end

      # Creates a new timeline to import the variations items under
      def initialize_timeline(timeline_xml, user)
        timeline = Timeline.new(user: user)
        timeline.title = construct_timeline_title(timeline_xml)
        timeline.visibility = 'private'
        timeline.description = timeline_xml.xpath('//Timeline/@description')
        timeline
      end

      def structures(timeline, node)
        children = node.xpath('child::Bubble').reject(&:blank?)
        if children.count > 1
          range = timeline_range(node)
          children.each do |n|
            newnode = structures(timeline, n)
            range[:items] << newnode if newnode.present?
          end
          # don't add parent ranges that only have one child, instead add child only
          if range[:items].present?
            range[:items].length == 1 && canvas_range?(range[:items][0]) ? range[:items][0] : range
          end
        else
          timeline_canvas(timeline, node)
        end
      end

      def annotations(timeline, timeline_xml)
        [
          {
            type: "AnnotationPage",
            items:
              timeline_xml.xpath('/Timeline/Markers/Marker').reject(&:blank?).collect do |n|
                timeline_annotation(timeline, n)
              end
          }
        ]
      end

      def timeline_annotation(timeline, node)
        {
          id: "marker-#{SecureRandom.uuid}",
          type: "Annotation",
          label: {
            en: [
              node.attribute('label')&.value
            ]
          },
          body: {
            type: "TextualBody",
            value: node.xpath('Annotation')&.text,
            format: "text/plain",
            language: "en"
          },
          target: {
            type: "SpecificResource",
            source: "#{Rails.application.routes.url_helpers.timeline_url(timeline)}/manifest/canvas",
            selector: {
              type: "PointSelector",
              t: node.attribute('offset')&.value.to_f / 1000
            }
          }
        }
      end

      def timeline_range(node)
        {
          'id': "id-#{SecureRandom.uuid}",
          'type': 'Range',
          'label': node_label(node),
          'summary': node_summary(node),
          'tl:backgroundColour': node_color(node),
          'items': []
        }.compact
      end

      def timeline_canvas(timeline, node)
        @timepoint_index ||= 0
        range = timeline_range(node)
        canvas = {
          'type': 'Canvas',
          'id': "#{Rails.application.routes.url_helpers.timeline_url(timeline)}/manifest/canvas#t=#{@timepoints[@timepoint_index]},#{@timepoints[@timepoint_index + 1]}"
        }
        @timepoint_index += 1
        range[:items] = [canvas]
        range
      end

      def canvas_range?(range)
        range[:items].length == 1 && range[:items][0][:type] == 'Canvas'
      end

      def rgb_to_hex(rgb_string)
        format("#%02x%02x%02x", *rgb_string.split(',')) if /^\d+,\d+,\d+$/.match? rgb_string
      end

      FLOAT_PATTERN = Regexp.new(/^\d+([.]\d*)?$/).freeze

      def parse_hour_min_sec(s)
        return nil if s.nil?
        smh = s.split(':').reverse
        (0..2).each do |i|
          smh[i] = FLOAT_PATTERN.match?(smh[i]) ? Float(smh[i]) : 0
        end
        smh[0] + (60 * smh[1]) + (3600 * smh[2])
      end

      def parse_media_fragment(fragment)
        return 0, nil unless fragment.present?
        f_start, f_end = fragment.split(',')
        [parse_hour_min_sec(f_start), parse_hour_min_sec(f_end)]
      end

      def construct_timeline_title(timeline_xml)
        timeline_title = extract_timeline_title(timeline_xml)
        if timeline_title.blank?
          timeline_title = Avalon::VariationsTimelineImporter::DEFAULT_TIMELINE_TITLE
        end
        timeline_title
      end

      # Determines the title of the timeline
      # @return [String] the timeline title or nil
      def extract_timeline_title(xml)
        xml.xpath('/Timeline/@title').text
      end

      def extract_timeline_duration(xml)
        xml.xpath('/Timeline/@mediaLength').text.to_f / 1000
      end

      def extract_timepoints(xml)
        xml.xpath('/Timeline/Timepoints/Timepoint').collect { |t| t.attribute('offset').value.to_f / 1000 }
      end

      def extract_background_color(xml)
        rgb_to_hex(xml.xpath('/Timeline/@bgColor')&.text)
      end

      def node_color(node)
        rgb_to_hex(node.attribute('color')&.value)
      end

      def node_label(node)
        language_encode(node.attribute('label')&.value || '')
      end

      def node_summary(node)
        language_encode(node.xpath('Annotation')&.text || '')
      end

      def language_encode(value)
        value.present? ? { 'en': [value] } : nil
      end
  end
end
