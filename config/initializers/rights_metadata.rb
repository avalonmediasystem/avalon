([Hydra::Datastream::RightsMetadata] + Hydra::Datastream::RightsMetadata.descendants).each do |mod|
  RightsMetadataExceptions.apply_to(mod)
end
