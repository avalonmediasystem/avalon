require 'rdf'
module Avalon
  module RDFVocab
    class Permalink < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/permalink#")
      property :hasPermalink, "rdfs:isDefinedBy" => %(avr-permalink:).freeze, type: "rdfs:Class".freeze
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

    class MasterFile < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/masterfile#")
      property :title,        "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :fileLocation,        "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :fileChecksum,        "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :fileSize,            "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :duration,            "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :displayAspectRatio,  "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :originalFrameSize,   "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :fileFormat,          "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :posterOffset,        "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :thumbnailOffset,     "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :dateDigitized,       "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :physicalDescription, "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
      property :masterFile,          "rdfs:isDefinedBy" => %(avr-masterfile:).freeze, type: "rdfs:Class".freeze
    end

    class Derivative < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/derivative#")
      property :locationURL,    "rdfs:isDefinedBy" => %(avr-derivative:).freeze, type: "rdfs:Class".freeze
      property :hlsURL,         "rdfs:isDefinedBy" => %(avr-derivative:).freeze, type: "rdfs:Class".freeze
      property :duration,       "rdfs:isDefinedBy" => %(avr-derivative:).freeze, type: "rdfs:Class".freeze
      property :trackID,        "rdfs:isDefinedBy" => %(avr-derivative:).freeze, type: "rdfs:Class".freeze
      property :hlsTrackID,     "rdfs:isDefinedBy" => %(avr-derivative:).freeze, type: "rdfs:Class".freeze
      property :isManaged,      "rdfs:isDefinedBy" => %(avr-derivative:).freeze, type: "rdfs:Class".freeze
      property :derivativeFile, "rdfs:isDefinedBy" => %(avr-derivative:).freeze, type: "rdfs:Class".freeze
    end

    class Encoding < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/encoding#")
      property :quality,        "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :mimeType,       "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :audioCodec,     "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :audioBitrate,   "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :videoCodec,     "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :videoBitrate,   "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :resolution,     "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
    end

    class MediaObject < RDF::StrictVocabulary("http://avalonmediasystem.org/rdf/vocab/mediaobject#")
      property :duration,        "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :avalon_resource_type,        "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :avalon_publisher,        "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :avalon_uploader,        "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
      property :identifier,        "rdfs:isDefinedBy" => %(avr-encoding:).freeze, type: "rdfs:Class".freeze
    end
  end
end
