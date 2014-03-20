<%#
Copyright 2011-2013, The Trustees of Indiana University and Northwestern
  University.  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.

You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed 
  under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
  CONDITIONS OF ANY KIND, either express or implied. See the License for the 
  specific language governing permissions and limitations under the License.
---  END LICENSE_HEADER BLOCK  ---
%>
/*
 * Since the mediaobject is not available in this context we have to assume the target
 * has been set by an earlier call to define post_path. This is sort of an ugly kludge
 * since it is leaky but works for a first cut.
 *
 * Another important note is that right now it assumes you want to go back to the
 * structural view. This is sort of brittle if you change up the workflow or want to
 * reorder directly from the file upload page.
 */
	  $('.sortable').sortable({ 
			disabled: false,
			update: function(e, ui) {
				var ordered_master_files = [];
				/*
				 * To provide the right order look at each row in the table and cherry
				 * pick the segments. This is a bit faster than going through the 
				 * entire DOM seeking for a class and retains some structure in the
				 * markup as well.
				 *
				 * For more information on using HTML5 data attributes check out
				 * http://html5doctor.com/html5-custom-data-attributes/
				 */
				$(this).find('tr').each(function(){
				  ordered_master_files.push($(this).data('segment'));
				});
                $('#ajax_confirmation').removeClass('hidden');
                
				$.ajax({
					data: { _method: 'update', 
					  masterfile_ids: ordered_master_files, 
					  step: 'structure', 
					  format: 'json' },
				    success: function(data) { 
				      $('#ajax_confirmation').addClass('hidden') },
 					type: 'PUT',
					url: post_path,
		       })
		   }
	  }).disableSelection().css('cursor', 'move');
  
    $(".sortable").nestedSortable({
      forcePlaceholderSize:true,
      handle: 'div',
      helper: 'clone',
      listType: 'tbody',
      items: 'tr',
      opacity: .6,
      revert: 250,
      tabSize: 25,
      tolerance: 'pointer',
      toleranceElement: '> div'
    }).disableSelection();
        
