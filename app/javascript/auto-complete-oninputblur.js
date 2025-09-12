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

Autocomplete.prototype.onInputBlur = function(event) {
  let target = event.explicitOriginalTarget
  // Target will either be the <li> element or the text node of the typeahead result.
  // The text nodes are wrapped in a span, so we need to look at the grandparent element
  // to get the <li> role.
  if ('option' === (target.role || target.parentElement.parentElement.role) ) return;
  this.close();
};
