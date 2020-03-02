/*
 * Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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
  let $image = $('#image');
  let $input = $('#poster_input');
  let $modal = $('#modal');
  let cropper;
  let width = 700;
  let aspectRatio = 5 / 4;
  $input.on('change', function (e) {
    let files = e.target.files;
    let done = function (url) {
      $image.prop("src", url);
      $modal.modal('show');
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
  $modal.on('shown.bs.modal', function () {
    cropper = new Cropper($image[0], {
      aspectRatio: aspectRatio,
      viewMode: 2,
    });
  }).on('hidden.bs.modal', function () {
    $input.val("");
    cropper.destroy();
    cropper = null;
  });
  $('#crop').on('click', function () {
    let canvas;
    let inputfile = $input.val().split('\\').pop();
    $modal.modal('hide');
    if (cropper) {
      canvas = cropper.getCroppedCanvas({
        width: width,
        height: width / aspectRatio,
      });
      canvas.toBlob(function (blob) {
        let formData = new FormData();
        $input.val("")
        formData.append('admin_collection[poster]', blob, inputfile);
        formData.append('authenticity_token', $('input[name=authenticity_token]').val());

        fetch(upload_path, {
          method: "POST",
          body: formData
        }).then(() => {
          // Page reload to show the flash message
          location.reload();
        });
      });
    }
  });
}
