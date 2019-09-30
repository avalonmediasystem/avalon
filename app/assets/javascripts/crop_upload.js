/*
 * Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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
  let $poster = $('#poster-image');
  let $image = $('#image');
  let $input = $('#poster_input');
  let $progress = $('#cropper-progress');
  let $progressBar = $('#cropper-progress-bar');
  let $alert = $('#cropper-alert');
  let $modal = $('#modal');
  let cropper;
  let width = 700;
  let aspectRatio = 16 / 9;
  $input.on('change', function (e) {
    let files = e.target.files;
    let done = function (url) {
      $image.prop("src", url);
      $alert.hide();
      $modal.modal('show');
    };
    let reader;
    let file;
    let url;
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
      viewMode: 3,
    });
  }).on('hidden.bs.modal', function () {
    cropper.destroy();
    cropper = null;
  });
  $('#crop-cancel').on('click', function () {
    $input.val("");
  })
  $('#crop').on('click', function () {
    let initialPosterURL;
    let canvas;
    $modal.modal('hide');
    if (cropper) {
      canvas = cropper.getCroppedCanvas({
        width: width,
        height: width / aspectRatio,
      });
      initialPosterURL = $poster.prop("src");
      $poster.prop("src", canvas.toDataURL());
      $progress.show();
      $alert.removeClass('alert-success alert-warning');
      canvas.toBlob(function (blob) {
        let formData = new FormData();
        let inputfile = $input.val().split('\\').pop();
        $input.val("")
        $('#poster_original_name').text(inputfile)
        formData.append('admin_collection[poster]', blob, inputfile);
        formData.append('authenticity_token', $('input[name=authenticity_token]').val())

        $.ajax(upload_path, {
          method: 'POST',
          data: formData,
          processData: false,
          contentType: false,
          xhr: function () {
            let xhr = new XMLHttpRequest();
            xhr.upload.onprogress = function (e) {
              let percent = '0';
              let percentage = '0%';
              if (e.lengthComputable) {
                percent = Math.round((e.loaded / e.total) * 100);
                percentage = percent + '%';
                $progressBar.width(percentage).attr('aria-valuenow', percent).text(percentage);
              }
            };
            return xhr;
          },
          success: function () {
            $alert.show().addClass('alert-success').text('Upload success');
          },
          error: function () {
            $poster.prop("src", initialPosterURL);
            $alert.show().addClass('alert-warning').text('Upload error');
          },
          complete: function () {
            $progress.hide();
          },
        });
      });
    }
  });
}
