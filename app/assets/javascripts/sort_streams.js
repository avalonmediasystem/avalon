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

$('.sortable').sortable({ 
  disabled: false,
  update: function(e, ui) {
    $('form > [name="master_file_ids[]"]').remove();

    $(this).find('li.section').each(function(){     
      $('<input>').attr({ 
        type: 'hidden', 
        name: 'master_file_ids[]',
        value: $(this).data('segment')
      }).appendTo('form');
    });

  }
}).disableSelection().css('cursor', 'move');

$(".sortable").nestedSortable({
  forcePlaceholderSize:true,
  handle: 'li.section',
  helper: 'clone',
  opacity: .6,
  revert: 250,
  tabSize: 25,
  tolerance: 'pointer',
  toleranceElement: 'ul'
}).disableSelection();
