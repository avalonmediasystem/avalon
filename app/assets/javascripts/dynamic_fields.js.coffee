# 
# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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
#

$ ->
  add_button_html = '<div class="input-group-btn"><button type="button" class="add-dynamic-field btn btn-success"><span class="glyphicon glyphicon-plus"></span></button></div>'
  remove_button_html = '<div class="input-group-btn"><button type="button" class="remove-dynamic-field btn btn-success"><span class="glyphicon glyphicon-minus"></span></button></div>'

  $('.form-group.multivalued').each ->
      t = $(this)
      t.find('.input-group:not(:last)').append(remove_button_html);
      t.find('.input-group:last').append(add_button_html);

      $(document).on 'click', '.add-dynamic-field', (e) ->
        e.preventDefault()
        current_input_group = $(this).closest('.input-group')
        new_input_group = current_input_group.clone()
        new_input_group.find('input').val('')
        if current_input_group.find('.twitter-typeahead').size()
          new_input = new_input_group.find('.tt-input').clone()
          new_input.removeClass('tt-input')
          new_input_group.find('.twitter-typeahead').before(new_input)
          new_input_group.find('.twitter-typeahead').remove()
          initialize_typeahead(new_input)
        else if current_input_group.find('.dropdown-menu').size()
          dropdown_default = current_input_group.find('.dropdown-menu li:first a').text()
          new_input_group.find('.dropdown-toggle span').first().text(dropdown_default)
          new_input_group.find('input[type="hidden"]').val(dropdown_default)
        current_input_group.find('.input-group-btn').has('.add-dynamic-field').remove()
        current_input_group.append(remove_button_html)
        current_input_group.after(new_input_group)
        
      $(document).on 'click', '.remove-dynamic-field', (e) ->
        e.preventDefault()
        $(this).closest('.input-group').remove()
