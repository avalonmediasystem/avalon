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
  const moveForm = getById('move_form');
  queryAll('.show_move_modal').forEach(function (element) {
    element.addEventListener('click', function () {
      const moveModal = getById('move_modal');
      if (moveModal) moveModal.style.display = 'block';
      // Set the URL for form POST action
      moveForm.setAttribute('action', `/master_files/${this.dataset.id}/move`);
    });
  });

  const moveModal = getById('move_modal');
  if (moveModal) {
    moveModal.addEventListener('shown.bs.modal', function () {
      const targetInput = getById('target');
      if (targetInput) targetInput.focus();
    });

    // Reset modal on close
    moveModal.addEventListener('hidden.bs.modal', function () {
      moveForm.reset();
      const showTargetObject = getById('show_target_object');
      if (showTargetObject) showTargetObject.innerHTML = '';
      const targetInput = getById('target');
      if (targetInput) {
        toggleCSS(targetInput, '', 'is-valid');
        toggleCSS(targetInput, '', 'is-invalid');
      }
      const moveActionBtn = getById('move_action_btn');
      if (moveActionBtn) moveActionBtn.disabled = true;
    });
  }
});

function previewTargetItem(obj) {
  const moid = obj.value.trim();
  const container = getById('show_target_object');
  const targetInput = getById('target');
  const moveActionBtn = getById('move_action_btn');

  if (moid.length < 8) {
    toggleCSS(targetInput, 'is-invalid', '');
  } else {
    fetch('/media_objects/' + moid + '/move_preview', {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
      .then(response => {
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        return response.json();
      })
      .then(data => {
        toggleCSS(targetInput, 'is-valid', 'is-invalid');
        moveActionBtn.disabled = false;
        const showObj = buildItemDetails(data);
        container.innerHTML = showObj;
      })
      .catch(() => {
        toggleCSS(targetInput, 'is-invalid', 'is-valid');
        moveActionBtn.disabled = true;
      });
  }
}

function buildItemDetails(json) {
  const html = [`<br /><h4>${json.title}</h4>`, `<p> In ${json.collection}</p>`];
  if (json.main_contributors.length > 0) {
    html.push(`<p> Main contributor(s), ${json.main_contributors}</p>`);
  }
  if (json.publication_date != null) {
    html.push(`<p> Published on, ${json.publication_date}</p>`);
  }
  json.published ? html.push('<p> Published</p>') : html.push('<p> Unpublished </p>');
  return html.join('\n');
}

// Add and remove CSS based on user input
function toggleCSS(el, addCls, removeCls) {
  if (!el) return;

  if (removeCls) {
    el.classList.remove(removeCls);
  }
  if (addCls && !el.classList.contains(addCls)) {
    el.classList.add(addCls);
  }
}

