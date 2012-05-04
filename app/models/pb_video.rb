class PbVideo < ActiveFedora::Base
  include Hydra::ModelMethods

  has_metadata :name => "descMetadata", :type => VideoPbcoreDatastream
  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata
end
