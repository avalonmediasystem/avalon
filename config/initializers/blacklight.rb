Blacklight::Facet.module_eval do
    def facet_paginator field_config, display_facet
      Blacklight::Solr::FacetPaginator.new(display_facet.items,
        sort: display_facet.sort,
        offset: display_facet.offset,
        limit: facet_limit_for(field_config.key),
        reverse: field_config.reverse)
    end
end

Blacklight::Solr::FacetPaginator.class_eval do
    # all_facet_values is a list of facet value objects returned by solr,
    # asking solr for n+1 facet values.
    # options:
    # :limit =>  number to display per page, or (default) nil. Nil means
    #            display all with no previous or next. 
    # :offset => current item offset, default 0
    # :sort => 'count' or 'index', solr tokens for facet value sorting, default 'count'. 
    # :reverse => true = descending, false = ascending
    def initialize(all_facet_values, arguments)
      # to_s.to_i will conveniently default to 0 if nil
      @offset = arguments[:offset].to_s.to_i
      @limit = arguments[:limit]
      # count is solr's default
      @sort = arguments[:sort] || "count"

      @all = all_facet_values

      @reverse = arguments[:reverse] || false
    end

    def items
      sorted_items = @reverse ? @all.reverse : @all
      items_for_limit(sorted_items)
    end
end
