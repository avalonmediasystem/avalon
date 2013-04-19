/* 
 * Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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
      this.add_button_to_controls();

      $(document).on('click', '.add-dynamic-field', function(event){
        /* When we click the add button we need to manipulate the parent container, which
	 * is a <div class="controls dynamic"> wrapper */
	/* CSS selectors are faster than doing a last() call in jQuery */
        var input_template = $(this).parent().find('input:last');
	/* By doing this we should just keep pushing the add button down as the last
	 * element of the parent container */
	var new_input = $(input_template).clone().attr('value', '');
        $(input_template).after(new_input);
      });
    },

    /* Simpler is better */
    add_button_to_controls: function() {
      var controls = $('.controls.dynamic').append(DynamicFields.add_input_html);
    },

    add_input_html: '<span class="add-dynamic-field muted"><i class="icon-plus"></i></span>'
  }
