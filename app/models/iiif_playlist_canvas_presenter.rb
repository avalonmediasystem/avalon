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
  attr_reader :playlist_item, :stream_info
  attr_accessor :media_fragment

  def initialize(playlist_item:, stream_info:, media_fragment: nil)
    @playlist_item = playlist_item
    @stream_info = stream_info
    @media_fragment = media_fragment
  end

  delegate :id, to: :playlist_item

  def to_s
    playlist_item.title
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

  def range
    simple_iiif_range
  end

  # @return [IIIFManifest::V3::DisplayContent] the display content required by the manifest builder.
  def display_content
    master_file.is_video? ? video_content : audio_content
  end

  def annotation_content
    playlist_item.marker.collect { |m| marker_content(m) }
  end

  private

    def video_content
      # @see https://github.com/samvera-labs/iiif_manifest
      stream_urls.collect { |quality, _url| video_display_content(quality) }
    end

    def video_display_content(quality)
      IIIFManifest::V3::DisplayContent.new(CGI.unescape(Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality, t: "#{playlist_item.start_time / 1000},#{playlist_item.end_time / 1000}")),
                                           **manifest_attributes(quality, 'Video'))
    end

    def audio_content
      stream_urls.collect { |quality, _url| audio_display_content(quality) }
    end

    def audio_display_content(quality)
      IIIFManifest::V3::DisplayContent.new(CGI.unescape(Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality, t: "#{playlist_item.start_time / 1000},#{playlist_item.end_time / 1000}")),
                                           **manifest_attributes(quality, 'Sound'))
    end

    def marker_content(marker)
      url = Rails.application.routes.url_helpers.avalon_marker_url(marker.id)

      IIIFManifest::V3::AnnotationContent.new(url, **marker_attributes(marker))
    end

    def stream_urls
      stream_info[:stream_hls].collect do |d|
        [d[:quality], d[:url]]
      end
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