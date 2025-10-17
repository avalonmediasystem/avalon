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
  // Localize UTC times on page load
  localize_times();

  // This interval is necessary to make sure CDL return time is calculated
  // and displayed on pages that have a Ramp player. The message renders in Ramp so 
  // we need to wait until it is initialized to run localize_times.
  let timeCheck = setInterval(initLocalizeTimes, 1000);
  function initLocalizeTimes() {
    // Check readyState to avoid constant interval polling on non-Ramp pages.
    if (document.readyState === 'complete') {
      // Clear interval once page is loaded
      clearInterval(timeCheck);
      localize_times();
    }
  }
});

// Requires moment.js
function localize_times() {
  const utcTimes = queryAll('*[data-utc-time]');
  utcTimes.forEach((t) => {
    t.textContent = moment(t.dataset['utc-time']).format('LLL');
  });
}
