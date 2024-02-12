# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

class IiifPlaylistManifestPresenter
  IIIF_ALLOWED_TAGS = ['a', 'b', 'br', 'i', 'img', 'p', 'small', 'span', 'sub', 'sup'].freeze
  IIIF_ALLOWED_ATTRIBUTES = ['href', 'src', 'alt'].freeze

  attr_reader :playlist, :items, :can_edit_playlist

  def initialize(playlist:, items:, can_edit_playlist: false)
    @playlist = playlist
    @items = items
    @can_edit_playlist = can_edit_playlist
  end

  def file_set_presenters
    items
  end

  def work_presenters
    []
  end

  def manifest_url
    Rails.application.routes.url_helpers.manifest_playlist_url(playlist)
  end

  def to_s
    playlist.title + ' [Playlist]'
  end

  def ranges
    [
      IiifManifestRange.new(
        label: { '@none'.to_sym => playlist.title },
        items: file_set_presenters.collect(&:range)
      )
    ]
  end

  def homepage
    [
      {
        id: Rails.application.routes.url_helpers.playlist_url(playlist),
        type: "Text",
        label: { "none" => [I18n.t('iiif.manifest.homepageLabel')] },
        format: "text/html"
      }
    ]
  end

  def viewing_hint
    ["auto-advance"]
  end

  def manifest_metadata
    @manifest_metadata ||= iiif_metadata_fields.compact
  end

  def service
    return nil unless can_edit_playlist
    [
      {
        id: Rails.application.routes.url_helpers.avalon_marker_index_url,
        type: "AnnotationService0"
      }
    ]
  end

  private

    def sanitize(value)
      Rails::Html::Sanitizer.safe_list_sanitizer.new.sanitize(value, tags: IIIF_ALLOWED_TAGS, attributes: IIIF_ALLOWED_ATTRIBUTES)
    end

    # Following methods adapted from ApplicationHelper and MediaObjectHelper
    def metadata_field(label, value, default = nil)
      sanitized_values = Array(value).collect { |v| sanitize(v.to_s.strip) }.delete_if(&:empty?)
      return nil if sanitized_values.empty? && default.nil?
      sanitized_values = Array(default) if sanitized_values.empty?
      label = label.pluralize(sanitized_values.size)
      { 'label' => label, 'value' => sanitized_values }
    end

    # TODO: playlist creator(?)
    def iiif_metadata_fields
      [
        metadata_field('Title', playlist.title + ' [Playlist]'),
        metadata_field('Description', playlist.comment),
        metadata_field('Tags', playlist.tags)
      ]
    end
end
