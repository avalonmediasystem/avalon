var errorMessage = '<p class="invalid-feedback">Please enter a valid ID</p>';

$('#move_modal').on('shown.bs.modal', function() {
  $('#target').focus();
  $('#target').addClass('is-invalid');
  $('#show_target_object').html(errorMessage);
  var masterFileID = $('#show_move_modal').data('id');
  $('#masterfile_id').val(masterFileID);
});

$('#move_modal').on('hidden.bs.modal', function(e) {
  $('#target').className = '';
  $('#move_form')[0].reset();
});

function searchMediaObject(obj) {
  var container = $('#show_target_object');
  var moid = obj.value;
  if (moid.length < 8) {
    toggleCSS($('#target'), 'is-invalid', '');
    container.html(errorMessage);
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
        container.html(errorMessage);
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

function toggleCSS(el, addCls, removeCls) {
  el.removeClass(removeCls);
  if (!el.hasClass(addCls)) {
    el.addClass(addCls);
  }
}
