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

  const browseBtn = getById('browse-btn');
  if (browseBtn) {
    //  TODO: Remove this dependency on jquery
    const browseEverythingInst = window.jQuery(browseBtn).browseEverything();
    browseEverythingInst.show(function () {
      const browseEverythingWorkflow = query('#browse-everything input[name=workflow]');
      if (!browseEverythingWorkflow) {
        const webUploadWorkflow = query('#web_upload input[name=workflow]');
        if (webUploadWorkflow) {
          const skip_box = webUploadWorkflow.closest('span').cloneNode(true);
          skip_box.className = '';
          skip_box.style.marginRight = '10px';
          const evCancel = query('.ev-cancel');
          if (evCancel) {
            evCancel.parentNode.insertBefore(skip_box, evCancel);
          }
        }
      }

      const providerLink = query('.ev-providers .ev-container a');
      if (providerLink) providerLink.click();
    }).done(function (data) {
      if (data.length > 0) {
        const uploadModalElement = getById('uploading');
        if (uploadModalElement) {
          const uploadModal = new bootstrap.Modal(uploadModalElement);
          uploadModal.show();
        }
        const dropboxWorkflowInput = query('#dropbox_form input[name=workflow]');
        const browseWorkflowChecked = query('#browse-everything input[name=workflow]:checked');
        if (dropboxWorkflowInput && browseWorkflowChecked) {
          dropboxWorkflowInput.value = browseWorkflowChecked.value;
        }
        const dropboxForm = getById('dropbox_form');
        if (dropboxForm) dropboxForm.submit();
      }
    });
  }
});
