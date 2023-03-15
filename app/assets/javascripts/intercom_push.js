/* 
 * Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

$('#intercom_push').on('shown.bs.modal', function(e) {
  getIntercomCollections(false);
});
function getIntercomCollections(force, collections_path) {
  select = $('#collection_id');
  if (force || select.find('option').length === 0) {
    $('#intercom_push_submit_button').prop('disabled', true);
    select.find('option').remove();
    select.append(
      '<option value="" disabled="disabled" selected="selected">Fetching Collections from Target...</option>'
    );
    $.ajax({
      type: 'GET',
      url: collections_path,
      format: 'json',
      data: { reload: force },
      success: function(result) {
        select.find('option').remove();
        $.each(result, function(i, c) {
          var option = $('<option></option')
            .attr('value', c['id'])
            .text(c['name']);
          if (c['default']) {
            option.prop('selected', true);
          }
          select.append(option);
        });
        $('#intercom_push_submit_button').prop('disabled', false);
      },
      error: function(result) {
        $('#intercom_push #collection_id')
          .find('option')
          .text('There was an error communicating with the target.');
      }
    });
  }
}
