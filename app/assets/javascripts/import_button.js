<<<<<<< HEAD
// Copyright 2011-2024, The Trustees of Indiana University and Northwestern
//   University.  Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.

// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
//   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied. See the License for the
//   specific language governing permissions and limitations under the License.
// ---  END LICENSE_HEADER BLOCK  ---

=======
/* 
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
>>>>>>> origin/develop

$(document).ready(function() {
  var form = $('div.import-button').closest('form').prop('id');
  var import_button_html = '<div class="input-group-append"><button id="media_object_bibliographic_id_btn" type="submit" name="media_object[import_bib_record]" class="btn btn-outline" value="yes" >Import</button></div>';
  $('div.import-button').append(import_button_html);
  $('#media_object_bibliographic_id_btn').popover({
    trigger: 'manual',
    html: true,
    sanitize: false,
    placement: 'top',
    container: 'body',
    content: function() {
      var button = `<button id="media_object_bibliographic_id_confirm_btn" class="btn btn-sm btn-danger btn-confirm" type="submit" name="media_object[import_bib_record]" value="yes" data-original-title="" title="" form="${form}" >Import</button>`
      return `<p>Note: this will replace all metadata except for Other Identifiers</p> ${button} <button id=\'cancel_bibimport\' class=\'btn btn-sm btn-primary\'>No, Cancel</button>`
    }
  });

  $('#media_object_bibliographic_id_btn').on('click', function() {
    import_val = document.getElementById('media_object_bibliographic_id').value;

    if ($('input#media_object_title').val() != '' && import_val != '') {
      $('#media_object_bibliographic_id_btn').popover('show');
      form_attribute_fix('#media_object_bibliographic_id_confirm_btn');
      return false;
    } else if (import_val == '') {
      return false;
    }
  });
  $(document).on('click', '#cancel_bibimport', function() {
    $('#media_object_bibliographic_id_btn').popover('hide');
    return true;
  });
});
