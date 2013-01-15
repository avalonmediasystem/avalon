module Blacklight::LocalBlacklightHelper 
  def facet_field_names group=nil
    blacklight_config.facet_fields.select { |facet,opts|
      ability = opts[:if_user_can]
      group == opts[:group] && (ability.nil? || can?(*ability))
    }.keys
  end

  def render_index_doc_actions(document, options={})   
    wrapping_class = options.delete(:wrapping_class) || "documentFunctions" 

    content = []
    content_tag("div", content.join("\n").html_safe, :class=> wrapping_class)
  end

  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style. And can be called by plugins to get consistent display. 
  def render_facet_count(num)
    content_tag("span", t('blacklight.search.facets.count', :number => num), :class => "badge") 
  end

  def link_to_document(doc, opts={:label=>nil, :counter => nil, :results_view => true})
    opts[:label] ||= blacklight_config.index.show_link.to_sym
    label = render_document_index_label doc, opts
    name = document_partial_name(doc)
    url = name.pluralize + "/" + doc["id"]
    link_to label, url, { :'data-counter' => opts[:counter] }.merge(opts.reject { |k,v| [:label, :counter, :results_view].include? k })
  end
end
