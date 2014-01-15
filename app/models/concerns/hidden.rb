module Avalon
  module AccessControls
    module Hidden
      extend ActiveSupport::Concern

      def hidden= value
        groups = self.discover_groups
        if value
          groups += ["nobody"]
        else
          groups -= ["nobody"]
        end
        self.discover_groups = groups.uniq
      end

      def hidden?
        self.discover_groups.include? "nobody"
      end

      def to_solr(solr_doc = Hash.new, opts = {})
        solr_doc[Solrizer.default_field_mapper.solr_name("hidden", type: :boolean)] = hidden?
        super(solr_doc, opts)
      end
    end
  end
end
