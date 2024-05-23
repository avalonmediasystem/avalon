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

require 'avalon/transcript_parser'

module Avalon
  class TranscriptSearch
    attr_reader :query, :master_file, :request_url

    def initialize(query:, master_file:, request_url: nil)
      @query = query
      @master_file = master_file
      @request_url = request_url
    end

    def perform_search
      terms = query.split
      term_subquery = terms.map { |term| "transcript_tsim:#{RSolr.solr_escape(term)}" }.join(" OR ")
      ActiveFedora::SolrService.get("isPartOf_ssim:#{master_file.id} AND #{term_subquery}",
                                    "fl": "id,mime_type_ssi",
                                    "hl": true,
                                    "hl.fl": "transcript_tsim",
                                    "hl.snippets": 1000000,
                                    "hl.fragsize": 0,
                                    "hl.method": "original")
    end

    def iiif_content_search
      results = perform_search

      {
        "@context": "http://iiif.io/api/search/2/context.json",
        id: request_url || "#{Rails.application.routes.url_helpers.search_master_file_url(master_file.id)}?q=#{query}",
        type: "AnnotationPage",
        items: items_builder(results)
      }
    end

    private

    def items_builder search_results
      formatted_response = []
      search_results["highlighting"].each do |result|
        transcript_id = result.first.split('/').last.to_i
        @mime_type = search_results["response"]["docs"].filter { |doc| doc["id"] == result.first }.first["mime_type_ssi"]
        @canvas = "#{Rails.application.routes.url_helpers.media_object_url(master_file.media_object_id).to_s}/manifest/canvas/#{master_file.id}"
        @target = Rails.application.routes.url_helpers.transcripts_master_file_supplemental_file_url(master_file.id, transcript_id)

        text_matches = result[1]["transcript_tsim"]

        formatted_response += process_items(text_matches)
      end

      formatted_response
    end

    def process_items(matches)
      formatted_matches = []

      matches.each do |cue|
        if @mime_type == 'text/vtt' || @mime_type == 'text/srt'
          time_cue, text = Avalon::TranscriptParser.extract_single_time_cue(cue)
        end

        text ||= cue

        formatted_matches += [format_item(text, @target, time_cue: time_cue)]
      end

      formatted_matches
    end

    def format_item(result, target, time_cue: nil)
      {
        id: "#{@canvas}/search/#{SecureRandom.uuid}",
        type: "Annotation",
        motivation: "supplementing",
        body: {
          type: "TextualBody",
          value: result,
          format: 'text/plain'
        },
        target: time_cue ? "#{target}#t=#{time_cue}" : target
      }
    end
  end
end