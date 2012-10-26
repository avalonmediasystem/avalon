module Blacklight::LocalBlacklightHelper 

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
end
