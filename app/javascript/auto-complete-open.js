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

import Autocomplete from '@github/auto-complete-element/dist/autocomplete.js'

Autocomplete.prototype.open = function(event) {
  const isHidden = this.results.popover ? !this.results.matches(':popover-open') : this.results.hidden
  if (isHidden) {
    this.combobox.start()
    if (this.results.popover) {
      this.results.showPopover()
    } else {
      this.results.hidden = false
    }
  }
  this.container.open = true
  this.interactingWithList = false
};
