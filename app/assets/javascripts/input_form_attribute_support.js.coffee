# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

# This script will enable support for the html5 form attribute
# This should only be needed for IE but is currently applied wholesale
# to all disjointed submit elements as is needed in some of the workflow steps
$ ->
  form_attribute_fix()

@form_attribute_fix = (selector = '*[type="submit"][form]') ->
  if not Modernizr.formattribute
    $(selector).click (event) ->
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
