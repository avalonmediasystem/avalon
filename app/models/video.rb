class Video < ActiveFedora::Base
  include Hydra::ModelMethods
#  include ActiveFedora::FileManagement

  has_metadata :name => "descMetadata", :type => VideoDCDatastream
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
end
