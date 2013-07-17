([Hydra::Datastream::RightsMetadata] + Hydra::Datastream::RightsMetadata.descendants).each do |mod|
  mod.class_eval do
    include RightsMetadataExceptions
  end
end