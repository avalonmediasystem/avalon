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

module MediaObjectIntercom
  def to_ingest_api_hash(include_structure = true, remove_identifiers: false, publish: false)
    {
      files: ordered_master_files.to_a.collect { |mf| mf.to_ingest_api_hash(include_structure, remove_identifiers: remove_identifiers) },
      fields:
        {
          duration: duration,
          avalon_resource_type: avalon_resource_type.to_a,
          avalon_publisher: (publish ? avalon_publisher : nil),
          avalon_uploader: avalon_uploader,
          identifier: (remove_identifiers ? [] : identifier.to_a),
          title: title,
          alternative_title: alternative_title,
          translated_title: translated_title,
          uniform_title: uniform_title,
          statement_of_responsibility: statement_of_responsibility,
          creator: creator,
          date_created: date_created,
          date_issued: date_issued,
          copyright_date: copyright_date,
          abstract: abstract,
          format: format,
          resource_type: resource_type,
          contributor: contributor,
          publisher: publisher,
          genre: genre,
          subject: subject,
          geographic_subject: geographic_subject,
          temporal_subject: temporal_subject,
          topical_subject: topical_subject,
          terms_of_use: terms_of_use,
          table_of_contents: table_of_contents,
          physical_description: physical_description,
          record_identifier: record_identifier,
          comment: comment.to_a,
          bibliographic_id: (bibliographic_id.present? ? bibliographic_id[:id] : nil),
          bibliographic_id_label: (bibliographic_id.present? ? bibliographic_id[:source] : nil),
          note: (note.present? ? note.collect { |n| n[:note] } : nil),
          note_type: (note.present? ? note.collect { |n| n[:type] } : nil),
          language: (language.present? ? language.collect { |n| n[:code] } : nil),
          related_item_url: (related_item_url.present? ? related_item_url.collect { |n| n[:url] } : nil),
          related_item_label: (related_item_url.present? ? related_item_url.collect { |n| n[:label] } : nil),
          other_identifier: (other_identifier.present? ? other_identifier.collect { |n| n[:id] } : nil),
          other_identifier_type: (other_identifier.present? ? other_identifier.collect { |n| n[:source] } : nil),
          rights_statement: rights_statement
        }
    }
  end
end
