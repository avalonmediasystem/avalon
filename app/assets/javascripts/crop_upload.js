/* 
 * Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

function add_cropper_handler(upload_path) {
  const image = getById('image');
  const input = getById('poster_input');
  const modal = getById('modal');
  let cropper;
  let width = 700;
  let aspectRatio = 5 / 4;

  input.addEventListener('change', function (e) {
    let files = e.target.files;
    let done = function (url) {
      image.src = url;
      const modalInstance = new bootstrap.Modal(modal);
      modalInstance.show();
    };
    let reader;
    let file;
    if (files && files.length > 0) {
      file = files[0];
      if (URL) {
        done(URL.createObjectURL(file));
      } else if (FileReader) {
        reader = new FileReader();
        reader.onload = function (e) {
          done(reader.result);
        };
        reader.readAsDataURL(file);
      }
    }
  });

  modal.addEventListener('shown.bs.modal', function () {
    cropper = new Cropper(image, {
      aspectRatio: aspectRatio,
      viewMode: 2,
    });
  });

  modal.addEventListener('hidden.bs.modal', function () {
    input.value = "";
    cropper.destroy();
    cropper = null;
  });

  getById('crop').addEventListener('click', function () {
    let canvas;
    let inputfile = input.value.split('\\').pop();
    if (modal) toggleModal(modal, false);
    if (cropper) {
      canvas = cropper.getCroppedCanvas({
        width: width,
        height: width / aspectRatio,
      });
      canvas.toBlob(function (blob) {
        let formData = new FormData();
        input.value = "";
        formData.append('admin_collection[poster]', blob, inputfile);
        formData.append('authenticity_token', query('input[name=authenticity_token]').value);

        // Display uploading in-progress
        const cropperProgress = getById('cropper-progress');
        cropperProgress.style.display = 'block';
        fetch(upload_path, {
          method: "POST",
          body: formData
        }).then(() => {
          // Hide uploading in-progress
          cropperProgress.style.display = 'none';
          // Page reload to show the flash message
          location.reload();
        });
      });
    }
  });
}
