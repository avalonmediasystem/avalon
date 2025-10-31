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

document.addEventListener('DOMContentLoaded', function () {
  const importButton = query('div.import-button');
  if (!importButton) return;

  const form = importButton.closest('form').id;
  const import_button_html = '<button id="media_object_bibliographic_id_btn" type="submit" name="media_object[import_bib_record]" class="btn btn-outline" value="yes">Import</button>';
  importButton.innerHTML += import_button_html;

  const bibImportButton = getById('media_object_bibliographic_id_btn');
  if (!bibImportButton) return;

  const importPopover = new bootstrap.Popover(bibImportButton, {
    trigger: 'manual',
    html: true,
    sanitize: false,
    placement: 'top',
    container: 'body',
    content: function () {
      const button = `<button id="media_object_bibliographic_id_confirm_btn" class="btn btn-sm btn-danger btn-confirm" type="submit" name="media_object[import_bib_record]" value="yes" data-original-title="" title="" form="${form}">Import</button>`;
      return `<p>Note: this will replace all metadata except for Other Identifiers</p> ${button} <button id='cancel_bibimport' class='btn btn-sm btn-primary'>No, Cancel</button>`;
    }
  });

  bibImportButton.addEventListener('click', function (e) {
    const import_val = getById('media_object_bibliographic_id').value;
    const title_val = query('input#media_object_title').value;

    if (title_val !== '' && import_val !== '') {
      importPopover.show();
      e.preventDefault();
      return false;
    } else if (import_val === '') {
      e.preventDefault();
      return false;
    }
  });

  document.addEventListener('click', function (e) {
    if (e.target && e.target.id === 'cancel_bibimport') {
      importPopover.hide();
    }
  });
});

