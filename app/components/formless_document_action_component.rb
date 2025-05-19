class FormlessDocumentActionComponent < Blacklight::Document::ActionComponent
  def link_to_modal_control
    link_to label,
            url,
            id: @id,
            class: @link_classes,
            method: 'post',
            data: {}.merge(({ blacklight_modal: "trigger", turbo: false } if @action.modal != false) || {})
  end
end