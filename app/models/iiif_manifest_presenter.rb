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

class IiifManifestPresenter
  include IiifSupplementalFileBehavior

  # Should <pre> tags be allowed?
  # They aren't listed in the IIIF spec but we use them in our normal view page
  IIIF_ALLOWED_TAGS = ['a', 'b', 'br', 'i', 'img', 'p', 'small', 'span', 'sub', 'sup'].freeze
  IIIF_ALLOWED_ATTRIBUTES = ['href', 'src', 'alt'].freeze

  attr_reader :media_object, :sections, :lending_enabled

  def initialize(media_object:, master_files:, lending_enabled: false)
    @media_object = media_object
    @sections = master_files
    @lending_enabled = lending_enabled
  end

  def file_set_presenters
    sections
  end

  def work_presenters
    []
  end

  def manifest_url
    Rails.application.routes.url_helpers.manifest_media_object_url(media_object)
  end

  def description
    media_object.abstract
  end

  def to_s
    media_object.title || media_object.id
  end

  def manifest_metadata
    @manifest_metadata ||= iiif_metadata_fields.compact
  end

  def thumbnail
    @thumbnail ||= thumbnail_url
  end

  def ranges
    [
      IiifManifestRange.new(
        label: { 'none' => [media_object.title] },
        items: file_set_presenters.collect(&:range)
      )
    ]
  end

  def homepage
    [
      {
        id: media_object.permalink.presence || Rails.application.routes.url_helpers.media_object_url(media_object),
        type: "Text",
        label: { "none" => [I18n.t('iiif.manifest.homepageLabel')] },
        format: "text/html"
      }
    ]
  end

  def viewing_hint
    ["auto-advance"]
  end

  def sequence_rendering
    supplemental_files_rendering(media_object)
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

  def combined_display_date(media_object)
    #FIXME Does this need to change now that date_issued is not required and thus could be nil
    result = media_object.date_issued
    result += " (Creation date: #{media_object.date_created})" if media_object.date_created.present?
    result
  end

  def display_other_identifiers(media_object)
    # bibliographic_id has form [:type,"value"], other_identifier has form [[:type,"value],[:type,"value"],...]
    ids = Array(media_object.other_identifier) - [media_object.bibliographic_id]
    return nil unless ids.present?
    ids.uniq.collect { |i| "#{ModsDocument::IDENTIFIER_TYPES[i[:source]]}: #{i[:id]}" }
  end

  def display_bibliographic_id(media_object)
    return nil unless media_object.bibliographic_id.present?
    "#{ModsDocument::IDENTIFIER_TYPES[media_object.bibliographic_id[:source]]}: #{media_object.bibliographic_id[:id]}"
  end

  def note_fields(media_object)
    fields = []
    note_types = ModsDocument::NOTE_TYPES.clone
    note_types['table of contents'] = 'Table of Contents'
    note_types['general'] = 'Notes'
    sorted_note_types = note_types.keys.sort
    sorted_note_types.prepend(sorted_note_types.delete('general'))
    sorted_note_types.each do |note_type|
      notes = note_type == 'table of contents' ? media_object.table_of_contents : gather_notes_of_type(media_object, note_type)
      fields << metadata_field(note_types[note_type], notes)
    end
    fields
  end

  def gather_notes_of_type(media_object, type)
    media_object.note.present? ? media_object.note.select { |n| n[:type] == type }.collect { |n| n[:note] } : []
  end

  def display_collection(media_object)
    "<a href='#{Rails.application.routes.url_helpers.collection_url(media_object.collection.id)}'>#{media_object.collection.name}</a>"
  end

  def display_unit(media_object)
    "<a href='#{Rails.application.routes.url_helpers.collections_url(filter: media_object.collection.unit)}'>#{media_object.collection.unit}</a>"
  end

  def display_language(media_object)
    return nil unless media_object.language.present?
    media_object.language.collect { |l| l[:text] }.uniq
  end

  def display_related_item(media_object)
    return nil unless media_object.related_item_url.present?
    media_object.related_item_url.collect { |r| "<a href='#{r[:url]}'>#{r[:label]}</a>" }
  end

  def display_series(media_object)
    media_object.series.collect { |s| "<a href='#{series_url(s)}'>#{s}</a>" }
  end

  def display_rights_statement(media_object)
    return nil unless media_object.rights_statement.present?
    label = ModsDocument::RIGHTS_STATEMENTS[media_object.rights_statement]
    return nil unless label.present?
    "<a href='#{media_object.rights_statement}'>#{label}</a>"
  end

  def display_summary(media_object)
    return nil unless media_object.abstract.present?
    media_object.abstract
  end

  def series_url(series)
    Rails.application.routes.url_helpers.blacklight_url({ "f[collection_ssim][]" => media_object.collection.name, "f[series_ssim][]" => series })
  end

  def display_search_linked(solr_field, values)
    Array(values).collect do |value|
      url = Rails.application.routes.url_helpers.blacklight_url({ "f[#{solr_field}][]" => RSolr.solr_escape(value) })
      "<a href='#{url}'>#{value}</a>"
    end
  end

  def display_lending_period(media_object)
    return nil unless lending_enabled
    ActiveSupport::Duration.build(media_object.lending_period).to_day_hour_s
  end

  def iiif_metadata_fields
    fields = [
      metadata_field('Title', media_object.title, media_object.id),
      metadata_field('Publication date', media_object.date_issued),
      metadata_field('Creation date', media_object.date_created),
      metadata_field('Main contributor', media_object.creator),
      metadata_field('Summary', display_summary(media_object)),
      metadata_field('Contributor', media_object.contributor),
      metadata_field('Publisher', media_object.publisher),
      metadata_field('Genre', media_object.genre),
      metadata_field('Subject', display_search_linked("subject_ssim", media_object.topical_subject)),
      metadata_field('Time period', media_object.temporal_subject),
      metadata_field('Location', media_object.geographic_subject),
      metadata_field('Collection', display_collection(media_object)),
      metadata_field('Unit', display_unit(media_object)),
      metadata_field('Language', display_language(media_object)),
      metadata_field('Rights Statement', display_rights_statement(media_object)),
      metadata_field('Terms of Use', media_object.terms_of_use),
      metadata_field('Physical Description', media_object.physical_description),
      metadata_field('Series', display_series(media_object)),
      metadata_field('Related Item', display_related_item(media_object)),
      metadata_field('Access Restrictions', media_object.access_text),
      metadata_field('Lending Period', display_lending_period(media_object))
    ]
    fields += note_fields(media_object)
    fields += [metadata_field('Bibliographic ID', display_bibliographic_id(media_object))]
    fields += [metadata_field('Other Identifier', display_other_identifiers(media_object))]
    fields
  end

  def thumbnail_url
    master_file_id = media_object.section_ids.try :first

    video_count = media_object.avalon_resource_type.map(&:titleize)&.count { |m| m.start_with?('moving image'.titleize) } || 0
    audio_count = media_object.avalon_resource_type.map(&:titleize)&.count { |m| m.start_with?('sound recording'.titleize) } || 0

    if master_file_id
      if video_count > 0
        Rails.application.routes.url_helpers.thumbnail_master_file_url(master_file_id)
      elsif audio_count > 0
        ActionController::Base.helpers.asset_url('audio_icon.png')
      end
    elsif video_count > 0 && audio_count > 0
      ActionController::Base.helpers.asset_url('hybrid_icon.png')
    elsif video_count > audio_count
      ActionController::Base.helpers.asset_url('video_icon.png')
    elsif audio_count > video_count
      ActionController::Base.helpers.asset_url('audio_icon.png')
    end
  end
end
