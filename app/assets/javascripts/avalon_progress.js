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

var AvalonProgress = (function () {
  let updateBar = undefined;
  AvalonProgress = class AvalonProgress {
    static initClass() {
      updateBar = (bar, attrs) => {
        for (let type in attrs) {
          const percent = attrs[type];
          const targetProgressbar = query(`.progress-bar.bg-${type}`, bar);
          if (targetProgressbar) {
            targetProgressbar.style.width = `${percent}%`;
          }
        }
      };

      this.prototype.data = {};
    }

    retrieve(auto) {
      if (auto == null) { auto = false; }
      const progressElement = getById('progress');
      if (!progressElement) return;

      const progressUrl = progressElement.dataset.progressUrl;

      return fetch(progressUrl, {
        headers: { 'Accept': 'application/json' }
      }).then(response => response.json())
        .then(data => {
          this.data = data;
          if (this.update() && auto) {
            setTimeout(() => {
              this.retrieve(auto);
            }, 10000);
          }
        })
        .catch(error => {
          console.error('Error fetching progress:', error);
        });
    }

    update() {
      // Update progress for media-object ingest in item view page
      if (this.data['overall'] != null) {
        const info = this.data['overall'];
        const overallBar = getById('overall');

        if (overallBar) {
          updateBar(overallBar, { success: info.success, danger: info.error });
          overallBar.dataset.status = JSON.stringify(info);
        }
        if (info.success === 100) {
          location.reload();
        }

        return (info.success + info.error) < 100;
      }
    }
  };
  AvalonProgress.initClass();
  return AvalonProgress;
})();

document.addEventListener('DOMContentLoaded', function () {
  // Do nothing if there are no progress element(s) or progress-url in progress element's dataset
  const container = query('#progress[data-progress-url]');
  if (!container) {
    return;
  }
  if (queryAll('.progress-bar', container).length === 0) {
    return;
  }

  const progress_controller = new AvalonProgress();
  progress_controller.retrieve(true);
});
