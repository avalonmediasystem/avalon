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

document.addEventListener('DOMContentLoaded', function () {
  document.addEventListener('click', function (event) {
    if (event.target.matches('a[data-bs-trigger="submit"]')) {
      const form = event.target.closest('form');
      if (form) form.submit();
    }
  });

  const browseBtn = document.getElementById('browse-btn');
  if (browseBtn) {
    const browseEverythingInst = window.jQuery(browseBtn).browseEverything();
    browseEverythingInst.show(function () {
      const browseEverythingWorkflow = document.querySelector('#browse-everything input[name=workflow]');
      if (!browseEverythingWorkflow) {
        const webUploadWorkflow = document.querySelector('#web_upload input[name=workflow]');
        if (webUploadWorkflow) {
          const skip_box = webUploadWorkflow.closest('span').cloneNode(true);
          skip_box.className = '';
          skip_box.style.marginRight = '10px';
          const evCancel = document.querySelector('.ev-cancel');
          if (evCancel) {
            evCancel.parentNode.insertBefore(skip_box, evCancel);
          }
        }
      }

      const providerLink = document.querySelector('.ev-providers .ev-container a');
      if (providerLink) providerLink.click();
    }).done(function (data) {
      if (data.length > 0) {
        const uploadModal = document.getElementById('uploading');
        if (uploadModal) {
          const uploadModal = new bootstrap.Modal(uploadModal);
          uploadModal.show();
        }
        const dropboxWorkflowInput = document.querySelector('#dropbox_form input[name=workflow]');
        const browseWorkflowChecked = document.querySelector('#browse-everything input[name=workflow]:checked');
        if (dropboxWorkflowInput && browseWorkflowChecked) {
          dropboxWorkflowInput.value = browseWorkflowChecked.value;
        }
        const dropboxForm = document.getElementById('dropbox_form');
        if (dropboxForm) dropboxForm.submit();
      }
    });
  }
});
