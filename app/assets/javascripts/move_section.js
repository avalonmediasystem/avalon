/*
 * Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

$('#show_move_modal').on('click', function(){
  $('#move_modal').show();
  var id = $(this).data('id');
  // Set the URL for form POST action
  $('#move_form').attr('action', '/master_files/' + id + '/move');
})

$('#move_modal').on('shown.bs.modal', function() {
  $('#target').focus();
});

function previewTargetItem(obj) {
  var container = $('#show_target_object');
  var moid = obj.value;
  if (moid.length < 8) {
    toggleCSS($('#target'), 'is-invalid', '');
  } else {
    $.ajax({
      url: '/media_objects/' + moid + '/move_preview',
      type: 'GET',
      success: function(data) {
        toggleCSS($('#target'), 'is-valid', 'is-invalid');
        $('#move_action_btn').prop('disabled', false);
        var showObj = buildItemDetails(data);
        container.html(showObj);
      },
      error: function(err) {
        toggleCSS($('#target'), 'is-invalid', 'is-valid');
        $('#move_action_btn').prop('disabled', true);
      }
    });
  }
}

function buildItemDetails(json) {
  var html = [
    '<br /><h4>' + json.title + '</h4>',
    '<p> In ' + json.collection + '</p>'
  ];
  if (json.main_contributors.length > 0) {
    html.push('<p> main contributor(s), ' + json.main_contributors + '</p>');
  }
  if (json.publication_date != null) {
    html.push('<p> published on, ' + json.publication_date + '</p>');
  }
  if (json.published) {
    html.push('<p> Published</p>');
  } else {
    html.push('<p> Unpublished </p>');
  }
  html.join('\n');
  return html;
}

// Add and remove CSS based on user input
function toggleCSS(el, addCls, removeCls) {
  el.removeClass(removeCls);
  if (!el.hasClass(addCls)) {
    el.addClass(addCls);
  }
}

// Reset modal on close
$('#move_modal').on('hidden.bs.modal', function(e) {
  $('#move_form')[0].reset();
  $('#show_target_object').html('');
  toggleCSS($('#target'), '', 'is-valid');
  toggleCSS($('#target'), '', 'is-invalid');
  $('#move_action_btn').prop('disabled', true);
});
