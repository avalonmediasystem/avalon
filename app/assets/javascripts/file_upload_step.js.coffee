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

$('.btn-confirmation+.popover .btn').live 'click', () ->
  $('.btn-confirmation').popover('hide')
  return true

$('.btn-confirmation')
  .popover
    trigger: 'manual',
    html: true,
    content: () ->
      "<p>Are you sure?</p>
      <a href='#{$(this).attr('href')}' class='btn btn-mini btn-danger btn-confirm' data-method='delete' rel='nofollow'>Yes, Delete</a>
      <a href='#' class='btn btn-mini btn-primary btn-cancel'>No, Cancel</a>"
    placement: 'left'
  .click () -> 
    t = this
    $('.btn-confirmation')
      .filter(() -> this isnt t)
      .popover('hide')
    $(this).popover('show')
    return false
