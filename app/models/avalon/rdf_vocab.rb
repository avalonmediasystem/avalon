require 'rdf'
module Avalon
  module RDFVocab
    class Common < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/common#")
      property :resolution,       "rdfs:isDefinedBy" => %(avr-common:).freeze, type: "rdfs:Class".freeze
    end

    class Transcoding < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/transcoding#")
      property :workflowId,       "rdfs:isDefinedBy" => %(avr-transcoding:).freeze, type: "rdfs:Class".freeze
      property :workflowName,     "rdfs:isDefinedBy" => %(avr-transcoding:).freeze, type: "rdfs:Class".freeze
      property :percentComplete,  "rdfs:isDefinedBy" => %(avr-transcoding:).freeze, type: "rdfs:Class".freeze
      property :percentSucceeded, "rdfs:isDefinedBy" => %(avr-transcoding:).freeze, type: "rdfs:Class".freeze
      property :percentFailed,    "rdfs:isDefinedBy" => %(avr-transcoding:).freeze, type: "rdfs:Class".freeze
      property :statusCode,       "rdfs:isDefinedBy" => %(avr-transcoding:).freeze, type: "rdfs:Class".freeze
      property :operation,        "rdfs:isDefinedBy" => %(avr-transcoding:).freeze, type: "rdfs:Class".freeze
      property :error,            "rdfs:isDefinedBy" => %(avr-transcoding:).freeze, type: "rdfs:Class".freeze
      property :failures,         "rdfs:isDefinedBy" => %(avr-transcoding:).freeze, type: "rdfs:Class".freeze
      property :encoderClassname, "rdfs:isDefinedBy" => %(avr-transcoding:).freeze, type: "rdfs:Class".freeze
    end

    class MasterFile < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/master_file#")
      property :posterOffset,        "rdfs:isDefinedBy" => %(avr-master_file:).freeze, type: "rdfs:Class".freeze
      property :thumbnailOffset,     "rdfs:isDefinedBy" => %(avr-master_file:).freeze, type: "rdfs:Class".freeze
    end

    class Derivative < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/derivative#")
      property :hlsURL,         "rdfs:isDefinedBy" => %(avr-derivative:).freeze, type: "rdfs:Class".freeze
      property :hlsTrackID,     "rdfs:isDefinedBy" => %(avr-derivative:).freeze, type: "rdfs:Class".freeze
      property :isManaged,      "rdfs:isDefinedBy" => %(avr-derivative:).freeze, type: "rdfs:Class".freeze
    end

    class Encoding < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/encoding#")
      property :audioCodec,     "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :audioBitrate,   "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
    end

    class MediaObject < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/media_object#")
      property :avalon_resource_type, "rdfs:isDefinedBy" => %(avr-media_object:).freeze, type: "rdfs:Class".freeze
      property :avalon_publisher,     "rdfs:isDefinedBy" => %(avr-media_object:).freeze, type: "rdfs:Class".freeze
      property :avalon_uploader,      "rdfs:isDefinedBy" => %(avr-media_object:).freeze, type: "rdfs:Class".freeze
    end

    class Collection < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/collection#")
      property :name,                     "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :unit,                     "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :description,              "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :dropbox_directory_name,   "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :default_read_users,       "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :default_read_groups,      "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :default_visibility,       "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :default_hidden,           "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :identifier,               "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
    end

    class Lease < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/lease#")
      property :begin_time,  "rdfs:isDefinedBy" => %(avr-lease:).freeze, type: "rdfs:Class".freeze
      property :end_time,    "rdfs:isDefinedBy" => %(avr-lease:).freeze, type: "rdfs:Class".freeze
    end
  end
end
