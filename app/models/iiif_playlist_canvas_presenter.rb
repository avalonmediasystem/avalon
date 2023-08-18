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

class IiifPlaylistCanvasPresenter
  attr_reader :playlist_item, :stream_info, :cannot_read_item
  attr_accessor :media_fragment

  def initialize(playlist_item:, stream_info:, cannot_read_item: false, media_fragment: nil)
    @playlist_item = playlist_item
    @stream_info = stream_info
    @cannot_read_item = cannot_read_item
    @media_fragment = media_fragment
  end

  delegate :id, to: :playlist_item

  def to_s
    if cannot_read_item
      "Restricted item"
    elsif master_file.nil?
      "Deleted item"
    else
      playlist_item.title
    end
  end

  def master_file
    playlist_item.clip.master_file
  end

  def part_of
    [{
      "@id" => Rails.application.routes.url_helpers.manifest_media_object_url(master_file.media_object_id).to_s,
      "type" => "manifest"
    }]
  end

  def item_metadata
    [
      { 'label' => { 'en' => ['Title'] }, 'value' => { 'en' => [master_file.media_object.title] } },
      { 'label' => { 'en' => ['Date'] }, 'value' => { 'en' => [master_file.media_object.date_created] } },
      { 'label' => { 'en' => ['Main Contributor'] }, 'value' => { 'en' => [master_file.media_object.creator] } }
    ]
   end

  def range
    simple_iiif_range(playlist_item.title)
  end

  # @return [IIIFManifest::V3::DisplayContent] the display content required by the manifest builder.
  def display_content
    return if cannot_read_item || master_file.nil?
    master_file.is_video? ? video_content : audio_content
  end

  def annotation_content
    return if cannot_read_item || master_file.nil?
    playlist_item.marker.collect { |m| marker_content(m) }
  end

  def placeholder_content
    if cannot_read_item
      IIIFManifest::V3::DisplayContent.new(nil,
                                           label: 'You do not have permission to playback this item.',
                                           type: 'Text',
                                           format: 'text/plain')
    elsif master_file.nil?
      IIIFManifest::V3::DisplayContent.new(nil,
                                           label: 'The source for this playlist item has been deleted.',
                                           type: 'Text',
                                           format: 'text/plain')
    end
  end

  private

    def video_content
      # @see https://github.com/samvera-labs/iiif_manifest
      stream_urls.collect { |quality, _url| video_display_content(quality) }
    end

    def video_display_content(quality)
      IIIFManifest::V3::DisplayContent.new(CGI.unescape(Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality, anchor: fragment_identifier)),
                                           **manifest_attributes(quality, 'Video'))
    end

    def audio_content
      stream_urls.collect { |quality, _url| audio_display_content(quality) }
    end

    def audio_display_content(quality)
      IIIFManifest::V3::DisplayContent.new(CGI.unescape(Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality, anchor: fragment_identifier)),
                                           **manifest_attributes(quality, 'Sound'))
    end

    def marker_content(marker)
      url = Rails.application.routes.url_helpers.avalon_marker_url(marker.id)

      IIIFManifest::V3::AnnotationContent.new(annotation_id: url, **marker_attributes(marker))
    end

    def stream_urls
      stream_info[:stream_hls].collect do |d|
        [d[:quality], d[:url]]
      end
    end

    def fragment_identifier
      "t=#{playlist_item.start_time / 1000},#{playlist_item.end_time / 1000}"
    end

    def simple_iiif_range(label = stream_info[:embed_title])
      # TODO: embed_title?
      IiifManifestRange.new(
        label: { "none" => [label] },
        items: [
          IiifPlaylistCanvasPresenter.new(playlist_item: playlist_item, stream_info: stream_info, media_fragment: "t=0,")
        ]
      )
    end

    def manifest_attributes(quality, media_type)
      media_hash = {
        label: quality,
        width: master_file.width.to_i,
        height: master_file.height.to_i,
        duration: stream_info[:duration],
        type: media_type,
        format: 'application/x-mpegURL'
      }.compact

      if master_file.media_object.visibility == 'public'
        media_hash
      else
        media_hash.merge!(auth_service: auth_service(quality))
      end
    end

    def marker_attributes(marker)
      {
        motivation: 'highlighting',
        type: 'TextualBody',
        value: marker.title,
        format: 'text/html',
        media_fragment: "t=#{marker.start_time / 1000}"
      }
    end

    def auth_service(quality)
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
            "@id": Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality),
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
