class Video < ActiveFedora::Base
  include Hydra::ModelMethods
  
  #has_metadata name: "dc", type: DublinCoreDocument
  has_metadata name: "descMetadata", type: PbcoreDocument
  delegate :title, to: 'descMetadata', at: 'title'
  delegate :creator, to: 'descMetadata', at: 'creator'
  delegate :created_on, to: 'descMetadata', at: 'created_on'

  has_metadata name: "rightsMetadata", type: Hydra::Datastream::RightsMetadata
end
