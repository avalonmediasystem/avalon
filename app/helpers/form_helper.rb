module FormHelper
  def render_metadata_input(attribute, input_type, *options, &block)
    logger.debug "<< Metadata Input helper >>"
    logger.debug "<< #{block} >>"

    label_content = case 
      when true 
        yield :label
      else
        attribute.to_s.humanize
    end
    content_tag(:div, class: 'control-group') {
      concat label_tag(label_content) 
    }
  end
end
