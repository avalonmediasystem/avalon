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
    const override_accessibility = this.checked ? '1' : '0';

    // AJAX request to update_status to toggle override_accessibility
    fetch(this.dataset.url, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken() },
      body: JSON.stringify({ override_accessibility })
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
    if (this.dataset.needsExemption !== 'true') {
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
    // Publish item with a11y exemption
    submitPublish(btn.dataset.publishUrl, true);
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

/**
 * Submit publish action with/without exemption. Pass `withExemption=true` to set
 * override_accessibility to true.
 * @param {String} url publish URL for item
 * @param {Boolean} withExemption flag to set override_accessibility, defaults to 'false'
 */
function submitPublish(url, withExemption = false) {
  const form = document.createElement('form');
  form.method = 'POST';
  form.action = url;
  form.appendChild(Object.assign(document.createElement('input'), {
    hidden: true, name: '_method', value: 'put'
  }));
  form.appendChild(Object.assign(document.createElement('input'), {
    hidden: true, name: 'authenticity_token', value: csrfToken()
  }));
  if (withExemption) {
    form.appendChild(Object.assign(document.createElement('input'), {
      hidden: true, name: 'override_accessibility', value: '1'
    }));
  }

  document.body.appendChild(form);
  form.submit();
}
