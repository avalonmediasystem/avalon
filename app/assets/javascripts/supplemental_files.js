
$('button[name="edit_label"]').on('click', e => {
  const { $row, fileId, masterFileId } = getHTMLInfo(e);
  const inputField = $row.find('input[name="label_' + masterFileId + '_' + fileId + '"]');
  inputField.val($row.data('file-label'));
  $row.addClass('is-editing');
  inputField.focus();
});

$('button[name="cancel_edit_label"]').on('click', e => {
  const { $row, fileId, masterFileId } = getHTMLInfo(e);
  $row.find('input[name="label_' + masterFileId + '_' + fileId + '"]');
  $row.removeClass('is-editing');
  });

$('button[name="save_label"]').on('click', e => {
  const {  $row, fileId, masterFileId } = getHTMLInfo(e);
  const newLabel = $row.find('input[name="label_' + masterFileId + '_' + fileId + '"]').val();
  $row.find('span[name="label_' + masterFileId + '_' + fileId + '"]').text(newLabel);

  let formData = new FormData();
  formData.append('supplemental_file[label]', newLabel);
  formData.append('authenticity_token', $('input[name=authenticity_token]').val());

  fetch('/master_files/' + masterFileId + '/supplemental_files/' + fileId, {
    method: "PUT",
    body: formData
  }).then(() => {
    $row.removeClass('is-editing');
    // Page reload to show the flash message
    location.reload();
  });
});

function getHTMLInfo(e) {
  const $row = $(e.target).parents('.row');
  const fileId = $row.data('file-id');
  const masterFileId = $row.data('masterfile-id');
  return {  $row, fileId, masterFileId };
}