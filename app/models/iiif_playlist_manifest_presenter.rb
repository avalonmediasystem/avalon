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

class IiifPlaylistManifestPresenter

  IIIF_ALLOWED_TAGS = ['a', 'b', 'br', 'i', 'img', 'p', 'small', 'span', 'sub', 'sup'].freeze
  IIIF_ALLOWED_ATTRIBUTES = ['href', 'src', 'alt'].freeze

  attr_reader :playlist, :items

  def initialize(playlist:, items:)
    @playlist = playlist
    @items = items
  end

  def file_set_presenters
    # Only return master files that have derivatives to avoid oddities in the manifest and failures in iiif_manifest
    items.select { |item| item.playlist_item.master_file.derivative_ids.size > 0 }
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

  # TODO: Metadata fields: Description (playlist_item.comment), tags, title, playlist creator(?)
end
