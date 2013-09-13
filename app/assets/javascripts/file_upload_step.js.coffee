section_form = $('#associated_files form')
button_form = $('#workflow_buttons form')
$('input[type=text]',section_form).each () ->
  $(this).change () ->
    double_id = "#{$(this).attr('id')}_double'"
    double = $("input[id='#{double_id}']",button_form)
    unless double.length > 0
      double = $("<input type='hidden' id='#{double_id}' 
        name='#{$(this).attr('name')}' 
        value='#{$(this).val()}'/>").appendTo(button_form)
    double.val($(this).val())
$('input[type=submit]',section_form).hide()

$('#delete_confirm .btn-cancel').click () ->
  $('#delete_confirm').modal('hide')

$('.btn-confirmation').click (event) ->
  modal = $('#delete_confirm')
  row = $(this).closest('tr')
  label = row.find('.section-label').val()
  label = if label? and (label != '') then "\"#{label.trim()}\"" else "this section"
  modal.find('#confirm_section_name').html(label)
  modal.find('.btn-confirm').attr('href',$(this).attr('href'))
  modal.modal('show')
  return false