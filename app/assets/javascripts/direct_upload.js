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

class DirectUpload {
  constructor(fileInput, form) {
    this.fileInput = fileInput;
    this.form = form;
    this.submitButton = query('input[type="submit"], *[data-trigger="submit"]', form);
    this.progressBar = null;
    this.uploadUrl = form.dataset.url;
    this.formData = form.dataset.formData ? JSON.parse(form.dataset.formData) : {};
    this.uploadedFiles = [];

    this.initUploads();
  }

  initUploads() {
    // Create progress bar
    this.progressBar = document.createElement('div');
    this.progressBar.className = 'bar';
    const progressBarContainer = document.createElement('div');
    progressBarContainer.className = 'progress';
    progressBarContainer.appendChild(this.progressBar);

    const fileinputDiv = query('div.fileinput');
    fileinputDiv.insertAdjacentElement('afterend', progressBarContainer);

    // Disable upload button on load
    this.submitButton.disabled = true;

    // Enable upload button when a file is selected
    this.fileInput.addEventListener('change', () => {
      this.submitButton.disabled = !this.fileInput.files.length;
    });

    // Bind submit button click to upload button
    this.submitButton.addEventListener('click', (e) => {
      e.preventDefault();
      this.upload();
      return false;
    });
  }

  upload() {
    const files = this.fileInput.files;
    if (!files || !files.length) return;

    // Disable upload button during upload
    this.submitButton.disabled = true;

    // Prepare form data
    const file = files[0];
    const formData = new FormData();
    Object.keys(this.formData).forEach(key => {
      formData.append(key, this.formData[key]);
    });
    formData.append('file', file);

    // Create XHR request
    const xhr = new XMLHttpRequest();

    // Track progress while uploading
    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable) {
        const progress = Math.round((e.loaded / e.total) * 100);
        this.progressBar.style.width = `${progress}%`;
      }
    });

    // Success handler
    xhr.addEventListener('load', () => {
      if (xhr.status === 201) {
        this.handleSuccess(xhr.responseXML);
      } else {
        this.handleError();
      }
    });

    // Error handler
    xhr.addEventListener('error', () => {
      this.handleError();
    });

    // Update progress bar on upload start
    this.form.classList.add('form-disabled');
    this.progressBar.style.display = 'block';
    this.progressBar.style.background = 'green';
    this.progressBar.style.width = '0%';
    this.progressBar.style.padding = '0px 7px 7px 7px';

    this.progressBar.textContent = 'Loading...';

    // Send the request
    xhr.open('POST', this.uploadUrl);
    xhr.send(formData);
  }

  handleSuccess(responseXML) {
    this.form.classList.remove('form-disabled');
    this.progressBar.textContent = 'Uploading done';

    // Extract key and generate URL from response
    const key = query('Key', responseXML).textContent;
    const bucket = query('Bucket', responseXML).textContent;
    const url = `s3://${bucket}/${key}`;

    // Create hidden input
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = 'selected_files[0][url]';
    input.value = url;

    this.fileInput.replaceWith(input);
    this.form.submit();
  }

  handleError() {
    this.form.classList.remove('form-disabled');
    this.progressBar.style.background = 'red';
    this.progressBar.textContent = 'Failed';
    // Re-enable upload button on error so user can retry
    this.submitButton.disabled = false;
  }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  const directUploadForms = queryAll('.directupload');

  directUploadForms.forEach(form => {
    const fileInput = query('input[type="file"]', form);
    if (fileInput) {
      new DirectUpload(fileInput, form);
    }
  });
});
