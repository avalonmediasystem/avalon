// Patch fix of https://github.com/projectblacklight/blacklight/pull/3694
// TODO: Remove this when on a version of blacklight that includes that PR
document.addEventListener('DOMContentLoaded', function () {
  // Make sure user-agent dismissal of html 'dialog', etc `esc` key, triggers
  // our hide logic, including events and scroll restoration.
  document.getElementById('blacklight-modal').addEventListener('cancel', (e) => {
    e.preventDefault(); // 'hide' will close the modal unless cancelled

    Blacklight.Modal.hide();
  });
});
