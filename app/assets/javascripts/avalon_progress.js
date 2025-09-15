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

var AvalonProgress = (function() {
  let setActive = undefined;
  let updateBar = undefined;
  AvalonProgress = class AvalonProgress {
    static initClass() {
      setActive = function(target, active) {
        if (active) { return target.addClass('progress-striped active'); } else { return target.removeClass('progress-striped active'); }
      };
  
      updateBar = (bar, attrs) => (() => {
        const result = [];
        for (let type in attrs) {
          const percent = attrs[type];
          const target = $(`.progress-bar.bg-${type}`,bar);
          result.push(target.css('width',`${percent}%`));
        }
        return result;
      })();
  
      this.prototype.data = {};
    }

    retrieve(auto) {
      if (auto == null) { auto = false; }
      return $.ajax($('#progress').data('progress-url'), {
        dataType: 'json',
        success: data => {
          this.data = data;
          if (this.update() && auto) {
            return setTimeout(() => {
              return this.retrieve(auto);
            }
            , 10000);
          }
        }
      }
      );
    }

    update() {
      const sections = $('a[data-segment]');
      sections.each((i,sec) => {
        const id = $(sec).data('segment');
        const section_node = $(sec).closest('.card-title');
        const bar = section_node.find('span.progress');
        const info_box = section_node.find('div.alert');

        const info = this.data[id];
        if (info != null) {
          setActive(bar, (info.complete < 100) && ((info.status === 'RUNNING') || (info.status === 'WAITING')));

          if (info.operation != null) { info_box.html(info.operation); }
          if (info.complete === 100) {
            info_box.html(info.status);
          }
          updateBar(bar, {success: info.success, danger: info.error});
          if (info.status === 'FAILED') {
            info_box.html(`ERROR: ${info.message}`);
            info_box.addClass('alert-error');
            info_box.show();
          }
  //         else
  //           updateBar(bar, 'bar-warning', 100)
          return bar.data('status',info);
        }
      });

      if ((info == null)) {
        if (this.data['overall'] != null) {
          var info = this.data['overall'];
          setActive($('#overall'), (info.success + info.error) < 100);

          updateBar($('#overall'), {success: info.success, danger: info.error});
          $('#overall').data('status',info);
          if (info.success === 100) {
            location.reload();
          }

          return (info.success + info.error) < 100;
        }
      }
    }
  };
  AvalonProgress.initClass();
  return AvalonProgress;
})();

$(document).ready(function() {
  if ($('.progress-bar').length === 0) {
    return;
  }

  const progress_controller = new AvalonProgress();

  $('.progress-indented').prepend(`\
<span class="progress progress-inline"> \
<div class="progress-bar bg-success" style="width:0%"></div> \
<div class="progress-bar bg-danger" style="width:0%"></div> \
<div class="progress-bar bg-warning" style="width:0%"></div> \
</span>`);
  $('.status-detail').hide();
  progress_controller.retrieve(true);
  return $('.progress-inline').click(function() {
    return $(this).nextAll('.status-detail').slideToggle();
  });
});
