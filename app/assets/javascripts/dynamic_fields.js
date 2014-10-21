/* 
 * Copyright 2011-2014, The Trustees of Indiana University and Northwestern
 *   University.  Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 * 
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software distributed 
 *   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 *   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
 *   specific language governing permissions and limitations under the License.
 * ---  END LICENSE_HEADER BLOCK  ---
*/

  window.DynamicFields = {

    initialize: function() {
      /* Any fields marked with the class 'dynamic_field' will have an add button appended
       * to the DOM after the label */	
      this.add_buttons_to_controls();

      $(document).on('click', '.add-dynamic-field', function(event){
        event.preventDefault();
        var current_input_group = $(this).closest('.input-group');
	var new_input_group = $(current_input_group).clone();
        new_input_group.find('input').val('');
        current_input_group.find('.input-group-btn').has('.add-dynamic-field').remove();
        current_input_group.append(DynamicFields.remove_button_html);
        $(current_input_group).after(new_input_group);
      });

      $(document).on('click', '.remove-dynamic-field', function(event){
        event.preventDefault();
        $(this).closest('.input-group').remove();
      });
    },

    /* Simpler is better */
    add_buttons_to_controls: function() {
      $('.form-group.multivalued').find('.input-group:not(:last)').append(DynamicFields.remove_button_html);
      $('.form-group.multivalued').find('.input-group:last').append(DynamicFields.add_button_html);
    },

    add_button_html: '<div class="input-group-btn"><button type="button" class="add-dynamic-field btn btn-success"><span class="glyphicon glyphicon-plus"></span></button></div>',
    remove_button_html: '<div class="input-group-btn"><button type="button" class="remove-dynamic-field btn btn-success"><span class="glyphicon glyphicon-minus"></span></button></div>'
  }
