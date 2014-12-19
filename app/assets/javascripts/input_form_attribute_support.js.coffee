# This script will enable support for the html5 form attribute
# This should only be needed for IE but is currently applied wholesale
# to all disjointed submit elements as is needed in some of the workflow steps
if not Modernizr.formattribute
  $('input[type="submit"][form]').click (event) ->
    event.preventDefault()
    form = document.getElementById($(this).attr('form'))
    newform = form.cloneNode()
    newform.id = newform.id + "_temp"
    $(document.body).append(newform)
    $('*[form="' + form.id + '"]').each (index, element) ->
      $(newform).append($(element).clone().attr('style', 'display:none'))
    $(form).find('input[type!="submit"]').each (index, element) ->
      $(newform).append($(element).clone().attr('style', 'display:none'))
    $(newform).find('textarea').each (index, element) ->
      $(elem).val($('#' + element.id).val())
    $(newform).find('select').each (index, element) ->
      $(elem).val($('#' + element.id).val())
    submit_element = $(this).clone().attr('style', 'display:none')
    $(newform).append(submit_element)
    $(submit_element).click()
    $(newform).remove()
