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


$ ->
  add_button_html = '<div class="input-group-append"><button type="button" class="add-dynamic-field btn btn-outline btn-light"><span class="fa fa-plus"></span></button></div>'
  remove_button_html = '<div class="input-group-append"><button type="button" class="remove-dynamic-field btn btn-outline btn-light"><span class="fa fa-minus"></span></button></div>'
  
  $('.form-group.multivalued').each ->
    t = $(this)
    t.find('.input-group').each (igIndex, e) ->
      $(e).find('input[id]').each (inIndex, e2) ->
        e2.id = e2.id + igIndex
      #Update typeahead targets
      $(e).find('input[data-target]').each (inIndex, e2) ->
        $(e2).attr('data-target', $(e2).attr('data-target') + igIndex)
    t.find('.input-group:not(:last)').append(remove_button_html);
    t.find('.input-group:last').append(add_button_html);

  $(document).on 'click', '.add-dynamic-field', (e) ->
    e.preventDefault()
    current_input_group = $(this).closest('.input-group')
    new_input_group = current_input_group.clone()
    new_input_group.find('input, textarea').val('')
    new_input_group.find('input[id], textarea[id]').each (i,e) ->
      idArray = e.id.split('_')
      idArray.push(parseInt(idArray.pop()) + 1)
      e.id = idArray.join('_')
    new_input_group.find('input[data-target], textarea[data-target]').each (i, e) ->
      target = $(e).attr('data-target').split('_')
      target.push(parseInt(target.pop()) + 1)
      $(e).attr('data-target', target.join('_'))
    if current_input_group.find('.twitter-typeahead').legth
      new_input = new_input_group.find('.tt-input').clone()
      new_input.removeClass('tt-input')
      new_input_group.find('.twitter-typeahead').before(new_input)
      new_input_group.find('.twitter-typeahead').remove()
      initialize_typeahead(new_input)
    else if current_input_group.find('.dropdown-menu').length
      dropdown_default_label = current_input_group.find('.dropdown-menu li:first a').text()
      dropdown_default_value = current_input_group.find('.dropdown-menu li:first span').text()
      new_input_group.find('.dropdown-toggle span').first().text(dropdown_default_label)
      new_input_group.find('input[type="hidden"]').val(dropdown_default_value)
    current_input_group.find('.input-group-append').has('.add-dynamic-field').remove()
    current_input_group.append(remove_button_html)
    textarea = current_input_group.data('textarea')
    if typeof(textarea) != "undefined"
      current_textarea = $(document.getElementById(textarea))
      new_textarea = current_textarea.clone()
      new_textarea.val('')
      idArray = new_textarea.attr('id').split('_')
      idArray.push(parseInt(idArray.pop()) + 1)
      new_textarea.attr('id', idArray.join('_'))
      new_input_group.attr('data-textarea', new_textarea.attr('id'))
      current_textarea.after(new_input_group)
      new_input_group.after(new_textarea)
    else
      current_input_group.after(new_input_group)
        
    $(document).on 'click', '.remove-dynamic-field', (e) ->
      e.preventDefault()
      current_input_group = $(this).closest('.input-group')
      textarea = current_input_group.data('textarea')
      if typeof(textarea)!="undefined"
        $(document.getElementById(textarea)).remove()
      current_input_group.remove()
