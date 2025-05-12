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

# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include Hydra::MultiplePolicyAwareAccessControlsEnforcement

  class_attribute :avalon_solr_access_filters_logic
  self.avalon_solr_access_filters_logic = [:only_published_items, :limit_to_non_hidden_items]
  self.default_processor_chain += [:only_wanted_models, :term_frequency_counts, :search_section_transcripts]

  def only_wanted_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'has_model_ssim:"MediaObject"'
  end

  def only_published_items(_permission_types = discovery_permissions, _ability = current_ability)
    [policy_clauses, 'workflow_published_sim:"Published"'].compact.join(" OR ")
  end

  def limit_to_non_hidden_items(_permission_types = discovery_permissions, _ability = current_ability)
    [policy_clauses,"(*:* NOT hidden_bsi:true)"].compact.join(" OR ")
  end

  # Overridden to skip for admin users
  def add_access_controls_to_solr_params(solr_parameters)
    if current_ability.cannot? :discover_everything, MediaObject
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << gated_discovery_filters.reject(&:blank?).join(' OR ')
      avalon_solr_access_filters_logic.each do |filter|
        solr_parameters[:fq] << send(filter, discovery_permissions, current_ability)
      end
      Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}")
    end
  end

  def search_section_transcripts(solr_parameters)
    return unless solr_parameters[:q].present? && SupplementalFile.with_tag('transcript').any? && !(blacklight_params[:controller] == 'bookmarks')

    return if solr_parameters[:q].match?(/[\{\}]/)
    # In order for the multi-word query to work we need to NOT escape the query AND replace the spaces as +; this is also true for quoted phrase searches
    transcript_subquery = "transcript_tsim:#{solr_parameters[:q].gsub(/ /, '+')}"
    solr_parameters[:defType] = "lucene"
    solr_parameters[:q] = "({!edismax v=\"#{RSolr.solr_escape(solr_parameters[:q])}\"}) {!join to=id from=isPartOf_ssim}{!join to=id from=isPartOf_ssim}#{transcript_subquery}"
  end

  def term_frequency_counts(solr_parameters)
    return unless solr_parameters[:q].present? && !(blacklight_params[:controller] == 'bookmarks')
    # Any search or filtering using a `q` parameter when transcripts are not present fails because
    # the transcript_tsim field does not get created. We need to only add the transcript searching
    # when transcripts are present.
    transcripts_present = SupplementalFile.with_tag('transcript').any?

    # List of fields for displaying on search results (Blacklight index fields)
    fl = ['id', 'has_model_ssim', 'title_tesi', 'alternative_title_ssim', 'date_issued_ssi', 'creator_ssim', 'abstract_ssi', 'duration_ssi', 'section_id_ssim', 'avalon_resource_type_ssim',
          'descMetadata_modified_dtsi', 'timestamp']

    # Add a field for matching child sections
    fl << "sections:[subquery]"
    solr_parameters["sections.q"] = "{!terms f=isPartOf_ssim v=$row.id}"
    solr_parameters["sections.defType"] = "lucene"
    solr_parameters["sections.rows"] = 1_000_000
    sections_fl = ['id']
    transcripts_fl = ['id'] if transcripts_present
   
    # Add fields for each term in the query 
    terms = solr_parameters[:q].split
    terms.each_with_index do |term, i|
      fl << "metadata_tf_#{i}:termfreq(mods_tesim,#{RSolr.solr_escape(term)})"
      fl << "structure_tf_#{i}:termfreq(section_label_tesim,#{RSolr.solr_escape(term)})"
      fl << "transcript_tf_#{i}" if transcripts_present
      sections_fl << "transcript_tf_#{i}" if transcripts_present
      transcripts_fl << "transcript_tf_#{i}:termfreq(transcript_tsim,#{RSolr.solr_escape(term)})" if transcripts_present
    end
    solr_parameters[:fl] = fl.join(',')

    return solr_parameters unless transcripts_present
    sections_fl << "transcripts:[subquery]"
    solr_parameters["sections.fl"] = sections_fl.join(',')
    solr_parameters["sections.transcripts.fl"] = transcripts_fl.join(',')
    solr_parameters["sections.transcripts.defType"] = "lucene"
    solr_parameters["sections.transcripts.rows"] = 1_000_000
    solr_parameters["sections.transcripts.q"] = "{!terms f=isPartOf_ssim v=$row.id}{!join to=id from=isPartOf_ssim}"
  end
end
