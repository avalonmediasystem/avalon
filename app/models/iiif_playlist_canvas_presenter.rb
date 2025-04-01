# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
  attr_reader :playlist_item, :stream_info, :cannot_read_item, :position
  attr_accessor :media_fragment

  def initialize(playlist_item:, stream_info:, cannot_read_item: false, position: nil, media_fragment: nil, master_file: nil)
    @playlist_item = playlist_item
    @stream_info = stream_info
    @cannot_read_item = cannot_read_item
    @position = position
    @media_fragment = media_fragment
    @master_file = master_file
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
    @master_file ||= playlist_item.clip.master_file
  end

  def part_of
    return if master_file.nil?
    [{
      "@id" => Rails.application.routes.url_helpers.manifest_media_object_url(master_file.media_object_id).to_s,
      "type" => "manifest"
    }]
  end

  def item_metadata
    return if master_file.nil?
    [
      metadata_field('Title', playlist_source_link),
      metadata_field('Date', master_file.media_object.date_issued),
      metadata_field('Main Contributor', master_file.media_object.creator)
    ].compact
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
    annotations = supplemental_captions.collect { |file| supplemental_captions_data(file) }
    annotations += playlist_item.marker.collect { |marker| marker_content(marker) }
  end

  def placeholder_content
    if cannot_read_item
      IIIFManifest::V3::DisplayContent.new(nil, **placeholder_attributes(I18n.t('playlist.restrictedText')))
    elsif master_file.nil?
      IIIFManifest::V3::DisplayContent.new(nil, **placeholder_attributes(I18n.t('playlist.deletedText')))
    elsif master_file.derivative_ids.empty?
      support_email = Settings.email.support
      IIIFManifest::V3::DisplayContent.new(nil, **placeholder_attributes(I18n.t('errors.missing_derivatives_error') % [support_email, support_email]))
    end
  end

  def description
    playlist_item.comment
  end

  def homepage
    [{
      "@id" => "#{Rails.application.routes.url_helpers.playlist_url(playlist_item.playlist_id).to_s}?position=#{position}",
      "type" => "Text",
      "label" => "Playlist Item #{position}"
    }]
  end

  private

    def playlist_source_link
      link_target = master_file.media_object.permalink.presence || Rails.application.routes.url_helpers.media_object_url(master_file.media_object_id)
      "<a href='#{link_target}'>#{master_file.media_object.title}</a>"
    end

    # Following methods adapted from ApplicationHelper and MediaObjectHelper
    def metadata_field(label, value, default = nil)
      sanitized_values = Array(value).delete_if(&:empty?)
      return nil if sanitized_values.empty? && default.nil?
      sanitized_values = Array(default) if sanitized_values.empty?
      label = label.pluralize(sanitized_values.size)
      { 'label' => { 'en' => [label] }, 'value' => { 'en' => sanitized_values } }
    end

    def video_content
      # @see https://github.com/samvera-labs/iiif_manifest
      stream_urls.collect { |quality, url, mimetype| video_display_content(quality, url, mimetype) }
    end

    def video_display_content(quality, url, mimetype)
      if mimetype.present? && mimetype != 'application/x-mpegURL'
        IIIFManifest::V3::DisplayContent.new(URI.join(url, "##{fragment_identifier}").to_s, **manifest_attributes(quality, 'Video', mimetype: mimetype))
      else
        IIIFManifest::V3::DisplayContent.new(CGI.unescape(Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality, anchor: fragment_identifier)),
                                             **manifest_attributes(quality, 'Video'))
      end
    end

    def audio_content
      stream_urls.collect { |quality, url, mimetype| audio_display_content(quality, url, mimetype) }
    end

    def audio_display_content(quality, url, mimetype)
      if mimetype.present? && mimetype != 'application/x-mpegURL'
        IIIFManifest::V3::DisplayContent.new(URI.join(url, "##{fragment_identifier}").to_s, **manifest_attributes(quality, 'Sound', mimetype: mimetype))
      else
        IIIFManifest::V3::DisplayContent.new(CGI.unescape(Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality, anchor: fragment_identifier)),
                                             **manifest_attributes(quality, 'Sound'))
      end
    end

    def marker_content(marker)
      url = Rails.application.routes.url_helpers.avalon_marker_url(marker.id)

      IIIFManifest::V3::AnnotationContent.new(annotation_id: url, **marker_attributes(marker))
    end

    def supplemental_captions
      files = master_file.supplemental_files(tag: 'caption')
      files += [master_file.captions] if master_file.captions.present? && master_file.captions.persisted?
      files
    end

    def supplemental_captions_data(file)
      url = if !file.is_a?(SupplementalFile)
              Rails.application.routes.url_helpers.captions_master_file_url(master_file.id)
            elsif file.tags.include?('caption')
              Rails.application.routes.url_helpers.captions_master_file_supplemental_file_url(master_file.id, file.id)
            end
      IIIFManifest::V3::AnnotationContent.new(body_id: url, **supplemental_attributes(file))
    end

    def supplemental_attributes(file)
      if file.is_a?(SupplementalFile)
        label = file.tags.include?('machine_generated') ? file.label + ' (machine generated)' : file.label
        format = file.file.content_type
        language = file.language || 'en'
      else
        label = 'English'
        format = file.mime_type
        language = 'en'
      end
      {
        motivation: 'supplementing',
        label: label,
        type: 'Text',
        format: format,
        language: language
      }
    end

    def stream_urls
      stream_info[:stream_hls].collect do |d|
        [d[:quality], d[:url], d[:mimetype]]
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
          IiifPlaylistCanvasPresenter.new(playlist_item: playlist_item, stream_info: stream_info, media_fragment: fragment_identifier, master_file: master_file)
        ]
      )
    end

    def manifest_attributes(quality, media_type, mimetype: 'application/x-mpegURL')
      media_hash = {
        label: quality,
        width: (master_file.width || '1280').to_i,
        height: (master_file.height || MasterFile::AUDIO_HEIGHT).to_i,
        duration: stream_info[:duration],
        type: media_type,
        format: mimetype
      }.compact

      if master_file.media_object.visibility == 'public'
        media_hash
      else
        media_hash.merge!(auth_service: auth_service(quality))
      end
    end

    def placeholder_attributes(label_content)
      placeholder_hash = {
        label: label_content,
        type: 'Text',
        format: 'text/plain',
        width: 1280,
        height: 720,
      }.compact
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
