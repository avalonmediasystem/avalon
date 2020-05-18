# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

class IiifCanvasPresenter
  attr_reader :master_file, :stream_info
  attr_accessor :media_fragment

  def initialize(master_file:, stream_info:, media_fragment: nil)
    @master_file = master_file
    @stream_info = stream_info
    @media_fragment = media_fragment
  end

  delegate :derivative_ids, :id, to: :master_file

  def to_s
    master_file.display_title
  end

  def range
    structure_ng_xml.root.blank? ? simple_iiif_range : structure_to_iiif_range
  end

  # @return [IIIFManifest::V3::DisplayContent] the display content required by the manifest builder.
  def display_content
    master_file.is_video? ? video_content : audio_content
  end

  private

    def video_content
      # @see https://github.com/samvera-labs/iiif_manifest
      stream_urls.collect { |quality, _url| video_display_content(quality) }
    end

    def video_display_content(quality)
      IIIFManifest::V3::DisplayContent.new(Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality),
                                           label: quality,
                                           width: master_file.width.to_i,
                                           height: master_file.height.to_i,
                                           duration: stream_info[:duration],
                                           type: 'Video',
                                           auth_service: auth_service)
    end

    def audio_content
      stream_urls.collect { |quality, _url| audio_display_content(quality) }
    end

    def audio_display_content(quality)
      IIIFManifest::V3::DisplayContent.new(Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality),
                                           label: quality,
                                           duration: stream_info[:duration],
                                           type: 'Sound',
                                           auth_service: auth_service)
    end

    def stream_urls
      stream_info[:stream_hls].collect do |d|
        [d[:quality], d[:url]]
      end
    end

    def simple_iiif_range
      # TODO: embed_title?
      IiifManifestRange.new(
        label: { '@none'.to_sym => [stream_info[:embed_title]] },
        items: [
          IiifCanvasPresenter.new(master_file: master_file, stream_info: stream_info, media_fragment: 't=0,')
        ]
      )
    end

    def structure_to_iiif_range
      div_to_iiif_range(structure_ng_xml.root)
    end

    def div_to_iiif_range(div_node)
      items = div_node.children.select(&:element?).collect do |node|
        if node.name == "Div"
          div_to_iiif_range(node)
        elsif node.name == "Span"
          span_to_iiif_range(node)
        end
      end

      # if a non-leaf node has no valid "Div" or "Span" children, then it would become empty range node containing no canvas
      # raise an exception here as this error shall have been caught and handled by the parser and shall never happen here
      raise Nokogiri::XML::SyntaxError, "Empty root or Div node: #{div_node[:label]}" if items.empty?

      IiifManifestRange.new(
        label: { '@none' => [div_node[:label]] },
        items: items
      )
    end

    def span_to_iiif_range(span_node)
      fragment = "t=#{parse_hour_min_sec(span_node[:begin])},#{parse_hour_min_sec(span_node[:end])}"
      IiifManifestRange.new(
        label: { '@none' => [span_node[:label]] },
        items: [
          IiifCanvasPresenter.new(master_file: master_file, stream_info: stream_info, media_fragment: fragment)
        ]
      )
    end

    FLOAT_PATTERN = Regexp.new(/^\d+([.]\d*)?$/).freeze

    def parse_hour_min_sec(s)
      return nil if s.nil?
      smh = s.split(':').reverse
      (0..2).each do |i|
        # Use Regexp.match? when we drop ruby 2.3 support
        smh[i] = smh[i] =~ FLOAT_PATTERN ? Float(smh[i]) : 0
      end
      smh[0] + (60 * smh[1]) + (3600 * smh[2])
    end

    # Note that the method returns empty Nokogiri Document instead of nil when structure_tesim doesn't exist or is empty.
    def structure_ng_xml
      # TODO: The XML parser should handle invalid XML files, for ex, if a non-leaf node has no valid "Div" or "Span" children,
      # in which case SyntaxError shall be prompted to the user during file upload.
      # This can be done by defining some XML schema to require that at least one Div/Span child node exists
      # under root or each Div node, otherwise Nokogiri::XML parser will report error, and raise exception here.
      @structure_ng_xml ||= (s = master_file.structuralMetadata.content).nil? ? Nokogiri::XML(nil) : Nokogiri::XML(s)
    end

    def auth_service
      {
        "context": "http://iiif.io/api/auth/1/context.json",
        "@id": Rails.application.routes.url_helpers.new_user_session_url(login_popup: 1),
        "@type": "AuthCookieService1",
        "confirmLabel": I18n.t('iiif.auth.confirmLabel'),
        "description": I18n.t('iiif.auth.description'),
        "failureDescription": I18n.t('iiif.auth.failureDescription'),
        "failureHeader": I18n.t('iiif.auth.failureHeader'),
        "header": I18n.t('iiif.auth.header'),
        "label": I18n.t('iiif.auth.label'),
        "profile": "http://iiif.io/api/auth/1/login",
        "service": [
          {
            "@id": Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: 'auto'),
            "@type": "AuthProbeService1",
            "profile": "http://iiif.io/api/auth/1/probe"
          },
          {
            "@id": Rails.application.routes.url_helpers.iiif_auth_token_url(id: master_file.id),
            "@type": "AuthTokenService1",
            "profile": "http://iiif.io/api/auth/1/token"
          },
          {
            "@id": Rails.application.routes.url_helpers.destroy_user_session_url,
            "@type": "AuthLogoutService1",
            "label": I18n.t('iiif.auth.logoutLabel'),
            "profile": "http://iiif.io/api/auth/1/logout"
          }
        ]
      }
    end
end
