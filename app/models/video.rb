class Video < ActiveFedora::Base
  include Hydra::ModelMethods

  has_metadata name: "dc", type: DublinCoreDocument
  has_metadata name: "descMetadata", type: PbcoreDocument
  has_metadata name: "rightsMetadata", type: Hydra::Datastream::RightsMetadata
end
