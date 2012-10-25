module Blacklight::LocalBlacklightHelper 

  def render_index_doc_actions(document, options={})   
    wrapping_class = options.delete(:wrapping_class) || "documentFunctions" 

    content = []
    content_tag("div", content.join("\n").html_safe, :class=> wrapping_class)
  end

end
