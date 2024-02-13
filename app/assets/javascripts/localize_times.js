/* 
 * Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

// Requires moment.js
function localize_times() {
  $('*[data-utc-time]').each(function() {
    $(this).text(moment($(this).data('utc-time')).format('LLL'))
  });
}

$(document).ready(localize_times);
$(document).on('draw.dt', localize_times);
// This interval is necessary to make sure CDL return time is calculated
// and displayed on pages that have a Ramp player. The message renders in Ramp so 
// we need to wait until it is initialized to run localize_times.
$(document).ready(function () {
  let timeCheck = setInterval(initLocalizeTimes, 500);
  function initLocalizeTimes() {
    // Check readyState to avoid constant interval polling on non-Ramp pages.
    if (document.readyState === 'complete') {
      clearInterval(timeCheck);
      localize_times();
    }
  }
});
