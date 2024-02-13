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

/*global Blacklight */

(function($) {
  'use strict';

  Blacklight.doResizeFacetLabelsAndCounts = function() {
    // adjust width of facet columns to fit their contents
    function longer(a, b) {
      return b.textContent.length - a.textContent.length;
    }

    $('ul.facet-values, ul.pivot-facet').each(function() {
      var longest = $(this)
        .find('span.facet-count')
        .sort(longer)[0];

      if (longest && longest.textContent) {
        var width = longest.textContent.length + 1 + 'ch';
        $(this)
          .find('.facet-count')
          .first()
          .width(width);
      }
    });
  };

  Blacklight.onLoad(function() {
    Blacklight.doResizeFacetLabelsAndCounts();
  });
}(jQuery));
