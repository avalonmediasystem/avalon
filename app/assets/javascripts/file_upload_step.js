// Copyright 2011-2025, The Trustees of Indiana University and Northwestern
//   University.  Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.

// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
//   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied. See the License for the
//   specific language governing permissions and limitations under the License.
// ---  END LICENSE_HEADER BLOCK  ---

const section_form = $('#associated_files form');
const button_form = $('#workflow_buttons form');
$('input[type=text]',section_form).each(function() {
  return $(this).change(function() {
    const double_id = `${$(this).attr('id')}_double'`;
    let double = $(`input[id='${double_id}']`,button_form);
    if (!(double.length > 0)) {
      double = $(`<input type='hidden' id='${double_id}' \
name='${$(this).attr('name')}' \
value='${$(this).val()}'/>`).appendTo(button_form);
    }
    return double.val($(this).val());
  });
});

$('.date-input').datepicker({
  dateFormat: 'yy-mm-dd'});

$('#file-input').change(() => $('.fileinput-submit').attr('disabled', false));
