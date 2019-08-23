$('#move_modal').on('shown.bs.modal', function() {
  $('#media_object_id').focus();
});

function searchMediaObject(obj) {
  var container = $('#show_target_object');
  var moid = obj.value;
  if (moid.length < 8) {
    obj.className = 'is-invalid';
    var showError = '<p class="invalid-feedback">Please enter a valid ID</p>';
    container.html(showError);
  } else {
    $.ajax({
      url: '/media_objects/' + moid + '/move_preview',
      type: 'GET',
      success: function(data) {
        obj.className = 'is-valid';
        $('#move_action_btn').prop('disabled', false);
        var showObj = buildItemDetails(data);
        container.html(showObj);
      },
      error: function(err) {
        obj.className = 'is-invalid';
        $('#move_action_btn').prop('disabled', true);
        var showError =
          '<p class="invalid-feedback">Please enter a valid ID</p>';
        container.html(showError);
      }
    });
  }
}

function buildItemDetails(json) {
  var html = [
    '<h3>' + json.title + '</h3>',
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

function submitForm() {
  var masterFileID = $('#show_move_modal').data('id');
  var targetID = $('#media_object_id').val();
  $.ajax({
    url: '/master_files/' + masterFileID + '/move?target=' + targetID,
    type: 'POST',
    success: function(response) {},
    error: function() {}
  });
  $('#move_form')[0].reset();
  $('#show_target_object').empty();
}
