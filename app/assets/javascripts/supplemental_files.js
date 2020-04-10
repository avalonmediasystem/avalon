
  $('button[name="edit_label"]').on('click', e => {
    const $row = $(e.target).parents('.row');
    const fileId = $row.data('file-id');
    console.log(fileId);

    $(e.target)
      .parents('.row')
      .addClass('is-editing');
  });

$('button[name="label_edit_cancel"]').on('click', e => {
    let $row = $(e.target).parents('.row');
    const fileId = $row.data('file-id');

    $row.removeClass('is-editing');
  });

$('button[name="save_label"]').on('click', e => {
    const $row = $(e.target).parents('.row');
    const fileId = $row.data('file-id');
    const masterFileId = $row.data('masterfile-id');
    const newLabel = $row.find('input[name="offset_' + fileId + '"]').val();

    let formData = new FormData();
      formData.append('supplemental_file[label]', newLabel);
      formData.append('authenticity_token', $('input[name=authenticity_token]').val());

    fetch('/master_files/' + masterFileId + '/supplemental_files/' + fileId, {
        method: "PUT",
        body: formData
      }).then(() => {
        // Page reload to show the flash message
        $row.removeClass('is-editing');
        location.reload();
      });
  });
