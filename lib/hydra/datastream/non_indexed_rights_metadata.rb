module Hydra
  module Datastream
    class NonIndexedRightsMetadata < Hydra::Datastream::RightsMetadata    
  
      @terminology = Hydra::Datastream::RightsMetadata.terminology

      def to_solr(solr_doc=Hash.new)
        return solr_doc
      end
    end
  end
end
