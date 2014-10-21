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

  window.DropdownTextFields = {

    initialize: function() {
      /* When dropdown-menu items are clicked, the text in the button is changed and
         also the value of the hidden input field.  */	

      $(document).on('click', '.dropdown-menu li', function(event){
        event.preventDefault();
	d = $(this);
	choice = d.text();
	btn_group = d.closest('.input-group-btn');
	btn_group.find('.dropdown-toggle span').first().text(choice)
	btn_group.find('input[type="hidden"]').val(choice);
      });
    },
  }
