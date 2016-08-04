# -*- encoding: utf-8 -*-
# This file generated automatically using vocab-fetch from http://purl.org/dc/dcmitype/
require 'rdf'
module Avalon
  module RDFVocab
    class Derivative < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/derivative#")
      property :locationURL,
        label: "LocationURL".freeze,
        "rdfs:isDefinedBy" => %(avalon:).freeze,
        type: "rdfs:Class".freeze
      property :hlsURL,
        label: "HlsURL".freeze,
        "rdfs:isDefinedBy" => %(avalon:).freeze,
        type: "rdfs:Class".freeze
      property :duration,
        "rdfs:isDefinedBy" => %(avalon:).freeze,
        type: "rdfs:Class".freeze
      property :trackID,
        "rdfs:isDefinedBy" => %(avalon:).freeze,
        type: "rdfs:Class".freeze
      property :hlsTrackID,
        "rdfs:isDefinedBy" => %(avalon:).freeze,
        type: "rdfs:Class".freeze
      property :isManaged,
        "rdfs:isDefinedBy" => %(avalon:).freeze,
        type: "rdfs:Class".freeze
      property :derivativeFile,
          "rdfs:isDefinedBy" => %(avalon:).freeze,
          type: "rdfs:Class".freeze
      property :quality,
          "rdfs:isDefinedBy" => %(avalon:).freeze,
          type: "rdfs:Class".freeze
      property :mime_type,
          "rdfs:isDefinedBy" => %(avalon:).freeze,
          type: "rdfs:Class".freeze
      property :audio_codec,
          "rdfs:isDefinedBy" => %(avalon:).freeze,
          type: "rdfs:Class".freeze
      property :audio_bitrate,
          "rdfs:isDefinedBy" => %(avalon:).freeze,
          type: "rdfs:Class".freeze
      property :video_codec,
          "rdfs:isDefinedBy" => %(avalon:).freeze,
          type: "rdfs:Class".freeze
      property :video_bitrate,
          "rdfs:isDefinedBy" => %(avalon:).freeze,
          type: "rdfs:Class".freeze
      property :resolution,
          "rdfs:isDefinedBy" => %(avalon:).freeze,
          type: "rdfs:Class".freeze
    end
    class MasterFile < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/master_file#")
      property :file_location,
               label: "file_location".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :file_checksum,
               label: "file_checksum".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :file_size,
               label: "file_size".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :duration,
               label: "duration".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :display_aspect_ratio,
               label: "display_aspect_ratio".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :original_frame_size,
               label: "original_frame_size".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :file_format,
               label: "file_format".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :poster_offset,
               label: "poster_offset".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :thumbnail_offset,
               label: "thumbnail_offset".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :date_digitized,
               label: "date_digitized".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :physical_description,
               label: "physical_description".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :masterFile,
               label: "masterFile".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :workflow_id,
               label: "workflow_id".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :workflow_name,
               label: "workflow_name".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :percent_complete,
               label: "percent_complete".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :percent_succeeded,
               label: "percent_succeeded".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :percent_failed,
               label: "percent_failed".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :status_code,
               label: "status_code".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :operation,
               label: "operation".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :error,
               label: "error".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :failures,
               label: "failures".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
      property :encoder_classname,
               label: "encoder_classname".freeze,
               "rdfs:isDefinedBy" => %(avalon:).freeze,
               type: "rdfs:Class".freeze
    end
  end
end
