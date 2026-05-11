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
    const errorMessage = this.dataset.errorMessage;

    fetch(this.dataset.url, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken() },
      body: JSON.stringify({ override_accessibility })
    })
      .then(response => response.json().then(data => ({ ok: response.ok, data })))
      .then(({ ok, data }) => {
        // Show an error and revert toggle if request fails
        if (!ok) {
          checkbox.checked = prevChecked;
          handleError(data.error || errorMessage);
          return;
        }
        checkbox.checked = data.exempt;
        const publishButton = document.getElementById('publish-btn');
        if (publishButton) {
          publishButton.dataset.needsExemption = data.exempt ? 'false' : 'true';
        }
      })
      .catch(() => {
        // Re-instate previous status
        checkbox.checked = prevChecked;
        handleError(errorMessage);
      });
  });
}

function handleError(message) {
  const errorAlert = document.getElementById('accessibility-override-error');
  if (errorAlert) errorAlert.remove();

  const alert = Object.assign(document.createElement('div'), {
    id: 'accessibility-override-error',
    className: 'alert alert-danger',
    data: { testid: 'alert' },
    innerHTML: `<button type="button" class="btn-close" data-bs-dismiss="alert" 
    aria-label="Close"></button><p>${message}</p>`
  });

  const alertsContainer = document.getElementById('alerts');
  if (alertsContainer) alertsContainer.prepend(alert);
  setTimeout(() => alert.remove(), 2000);
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
