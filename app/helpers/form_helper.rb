module FormHelper
  def render_metadata_input(attribute, input_type, *options, &block)
    content_tag(:div, class: 'control-group') {
      concat label_tag(:attribute) 
    }
  end
end
