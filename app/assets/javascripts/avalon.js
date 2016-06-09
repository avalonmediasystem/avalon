/* 
 * Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

// Empty file for future js
/* Override the search_context so it stops POSTing links which confuses
 * Rails and causes it to redirect to the wrong place. */
$(document).ready(function() {
  Blacklight.do_search_context_behavior = function() {}
  // adjust width of facet columns to fit their contents
  function longer (a,b){ return b.textContent.length - a.textContent.length; }
  $('ul.facet-values, ul.pivot-facet').map(function(){
      var longest = $(this).find('.facet-count span').sort(longer).first();
      var clone = longest.clone().css('visibility','hidden');
      $('body').append(clone);
      $(this).find('.facet-count').first().width(clone.width());
      clone.remove();
  });

  $( document ).on('click', '.btn-stateful-loading', function() { $(this).button('loading'); });    

  $(document).on("click", ".btn-confirmation+.popover .btn", function() {
      $('.btn-confirmation').popover('hide');
      return true;
  });

  $('.btn-confirmation').popover({
      trigger: 'manual',
      html: true,
      content: function() {
        var button;
	if ( typeof $(this).attr('form') === typeof undefined) {
	    button = "<a href='" + ($(this).attr('href')) + "' class='btn btn-xs btn-danger btn-confirm' data-method='delete' rel='nofollow'>Yes, Delete</a>";
        } else {
            button = '<input class="btn btn-xs btn-danger btn-confirm" form="'+$(this).attr('form')+'" type="submit">';
            $('#'+$(this).attr('form')).find("[name='_method']").val("delete");
	}
        return "<p>Are you sure?</p> "+button+" <a href='#' class='btn btn-xs btn-primary' id='special_button_color'>No, Cancel</a>";
    }
  }).click(function() {
    var t = this;
    $('.btn-confirmation').filter(function() {
      return this !== t;
    }).popover('hide');
    $(this).popover('show');
    return false;
  });

  $('.popover-target').popover({
    placement: 'top',
    html: true,
    trigger: 'hover',
    delay: { show: 250, hide: 500 },
    content: function() { 
      return $(this).next('.po-body').html() 
    }
  });

  $('#show_object_tree').on('click', function() {
    var ot = $('#object_tree')
    ot.load(ot.data('src'));
    return false;
  })

  var iOS = !!/(iPad|iPhone|iPod)/g.test( navigator.userAgent );
  if (iOS) {
    $('input[readonly], textarea[readonly]').on('cut paste keydown', function(e) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    })
    $('input[readonly], textarea[readonly]').attr("readonly", false);
  }

  $('a').has('img, ul').addClass('block');

  window.addEventListener("hashchange", function(event) {
    var element = document.getElementById(location.hash.substring(1));
    if (element) {
      if (!/^(?:a|select|input|button|textarea)$/i.test(element.tagName)) {
        element.tabIndex = -1;
      }
      element.focus();
    }
  }, false);

  $( "#content" ).focus( function() {
    $( ".mejs-controls" ).css( "visibility", "visible" );
    $( ".mejs-controls button:first" ).focus();
  })

});
