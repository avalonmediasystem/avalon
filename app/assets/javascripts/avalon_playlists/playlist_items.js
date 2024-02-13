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

// This is for the playlists edit page
Blacklight.onLoad(function(){

  // Display the drag handle
  $('.dd-handle').removeClass('hidden');

  // Initialize drag-and-drop behavior
  $('.dd').nestable({ maxDepth: 1, dropCallback: function(data){
    allItemsData = $('.dd').nestable('serialize');
    itemsContainer = $('.dd');
    reorderItems(allItemsData, itemsContainer);
  } });

  var reorderItems = function(data, container) {
    var playlistId = container.data('playlist_id');
    var items = data;
    for(var i in data){
      items[i]['position'] = (parseInt(i) + 1).toString();
    }

    $.ajax({
      type: "PATCH",
      url: '/playlists/' + playlistId + '.json',
      data: { playlist: {items_attributes: items}},
      success: function(data, status){
      }
    });

    // Update the position text in the form
    var textElements = $('.dd .position-input');
    for(var i in textElements) {
      textElements[i].value = parseInt(i) + 1;
    }
  };

});
