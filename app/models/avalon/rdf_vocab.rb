# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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
      property :supplementalFiles,   "rdfs:isDefinedBy" => %(avr-master_file:).freeze, type: "rdfs:Class".freeze
      property :thumbnailOffset,     "rdfs:isDefinedBy" => %(avr-master_file:).freeze, type: "rdfs:Class".freeze
      property :workingFilePath,     "rdfs:isDefinedBy" => %(avr-master_file:).freeze, type: "rdfs:Class".freeze
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
      property :website_label,            "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :dropbox_directory_name,   "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :default_read_users,       "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :default_read_groups,      "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :default_visibility,       "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
      property :default_hidden,           "rdfs:isDefinedBy" => %(avr-collection:).freeze, type: "rdfs:Class".freeze
    end
  end
end
