require "hydra/submission_workflow"
module ShowWorkflowHelper
  include Hydra::SubmissionWorkflow
  
    def render_all_show_workflow_steps
    "#{all_show_partials.map{|partial| render partial}}"
  end

  # Returns an array of all show partials for the current content type.
  def all_show_partials
    show_partials = []
    unless model_config.nil?
      model_config.each do |config|
        show_partials << config[:show_partial] unless not editor? and (config[:name] == "permissions" || config[:name] == "files")
      end
    end
    show_partials
  end

  def get_data_with_label(doc, label, field_string, opts={})
    if opts[:default] && !doc[field_string]
      doc[field_string] = opts[:default]
    end
    
    if doc[field_string]
      field = doc[field_string]
      text = "<dt>#{label}</dt><dd>"
      if field.is_a?(Array)
          field.each do |l|
            text += "#{h(l)}"
            if l != h(field.last)
              text += "<br/>"
            end
          end
      else
        text += h(field)
      end
      #Does the field have a vernacular equivalent? 
      if doc["vern_#{field_string}"]
        vern_field = doc["vern_#{field_string}"]
        text += "<br/>"
        if vern_field.is_a?(Array)
          vern_field.each do |l|
            text += "#{h(l)}"
            if l != h(vern_field.last)
              text += "<br/>"
            end
          end
        else
          text += h(vern_field)
        end
      end
      text += "</dd>"
    end
  end

end
