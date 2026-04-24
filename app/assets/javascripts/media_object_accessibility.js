/*
 * Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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

/** Read CSRF-token */
function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]').content;
}

document.addEventListener('DOMContentLoaded', function () {
  initAccessibilityToggle();
  initPublishPopover();
});

function initAccessibilityToggle() {
  const checkbox = document.getElementById('accessibility_exempt_toggle');
  if (!checkbox) return;

  checkbox.addEventListener('change', function () {
    const prevChecked = !this.checked;
    const exempt = this.checked ? '1' : '0';

    // AJAX request to update exempt status for publication
    fetch(this.dataset.url, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken() },
      body: JSON.stringify({ exempt })
    })
      .then(response => response.json())
      .then(res => {
        // Update exempt status for publish button to show/hide popover on click
        checkbox.checked = res.exempt;
        const publishButton = document.getElementById('publish-btn');
        if (publishButton) {
          publishButton.dataset.needsExemption = res.exempt ? 'false' : 'true';
        }
      })
      .catch(() => {
        console.error('Exempt check request failed!');
        // Re-instate previous status
        checkbox.checked = prevChecked;
      });
  });
}

function initPublishPopover() {
  const btn = document.getElementById('publish-btn');
  if (!btn) return;

  btn.addEventListener('click', function (e) {
    if (this.dataset.needsExemption !== 'true' || !this.dataset.exemptUrl) {
      submitPublish(this.dataset.publishUrl);
    } else {
      e.preventDefault();
      e.stopPropagation();
      const existing = bootstrap.Popover.getInstance(btn);
      if (existing) {
        existing.show();
      } else {
        new bootstrap.Popover(btn, {
          trigger: 'manual',
          html: true,
          sanitize: false,
          container: '#main-content',
          content: `<p>${this.dataset.confirmationMessage || ''}</p>` +
            '<button class="btn btn-sm btn-warning me-2" id="exempt-and-publish-btn">Exempt &amp; Publish</button>' +
            '<button class="btn btn-sm btn-primary" id="cancel-publish-btn">Cancel</button>'
        }).show();
      }
    }
  });
}

document.addEventListener('click', function (e) {
  /** Exempt and publish action from popover */
  if (e.target.id === 'exempt-and-publish-btn') {
    e.preventDefault();
    const btn = document.getElementById('publish-btn');
    const exemptUrl = btn.dataset.exemptUrl;
    const publishUrl = btn.dataset.publishUrl;
    const token = document.querySelector('meta[name="csrf-token"]').content;

    fetch(exemptUrl, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
      body: JSON.stringify({ exempt: '1' })
    })
      .then(response => response.json())
      .then(() => submitPublish(publishUrl))
      .catch(() => {
        const popoverInstance = bootstrap.Popover.getInstance(btn);
        if (popoverInstance) popoverInstance.hide();
        btn.focus();
      });
  }

  /** Cancel action from popover */
  if (e.target.id === 'cancel-publish-btn') {
    e.preventDefault();
    const btn = document.getElementById('publish-btn');
    const popover = bootstrap.Popover.getInstance(btn);
    if (popover) popover.hide();
    btn.focus();
  }
});

/** Submit publish action */
function submitPublish(url) {
  const form = document.createElement('form');
  form.method = 'POST';
  form.action = url;

  const method = document.createElement('input');
  method.type = 'hidden';
  method.name = '_method';
  method.value = 'put';

  const token = document.createElement('input');
  token.type = 'hidden';
  token.name = 'authenticity_token';
  token.value = csrfToken();

  form.appendChild(method);
  form.appendChild(token);
  document.body.appendChild(form);
  form.submit();
}
