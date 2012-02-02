class Video < ActiveFedora::Base
  include Hydra::ModelMethods

  has_metadata :name => "descMetadata", :type => VideoDCDatastream
  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata
end
