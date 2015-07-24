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

  // If .avalon-player exists keyboardAccess loads from the success callback
  if ( $( ".avalon-player" ).length == 0 ) {
    keyboardAccess();
  }
});


var keyboardAccess = function() {
    var interactive_elements = [ "a", "input", "button", "textarea" ];
    var outline_on = true;

    function addElementOutline( element ) {
      $( element ).on( "focus", function() {
        if ( outline_on ) {
          var player = $( ".avalon-player" )[ 0 ];
          if ( player && $.contains( player, $( this )[ 0 ] )) {
            $( this ).addClass( "player_element_outline" );
          } else {
            $( this ).addClass( "page_element_outline" )
          }
        }
      })
    };

    function removeElementOutline( element ) {
      $( element ).on( "blur", function() {
        if ( outline_on ) {
          var player = $( ".avalon-player" )[ 0 ];
          if ( player && $.contains( player, $( this )[ 0 ] )) {
            $( this ).removeClass( "player_element_outline" );
          } else {
            $( this ).removeClass( "page_element_outline" )
          }
        }
      })
    };

    function hideOutlineForMouse( element ) {
      $( element ).on( "mouseover", function() {
        outline_on = false;
      });
      $( element ).on( "mouseout", function() {
        outline_on = true;
      });
    };

    function interactiveElements() {
      $.each( interactive_elements, function( index, value ) {
        addElementOutline( value );
        removeElementOutline( value );
        hideOutlineForMouse( value );
      });
    }

    interactiveElements();

    $( ".avalon-player" ).mouseover( function() {
      outline_on = false;
    });

    $( ".avalon-player" ).mouseout( function() {
      outline_on = true;
    });

    // Tab in and out of the player
    function tabIntoPlayer( e ) {
      if ( !e.shiftKey && e.keyCode == 9 ) {
        $( ".mejs-controls" ).css( "visibility", "visible" );
        $( ".mejs-controls button:first" ).focus();
      }
    }

    if ( $( "#administrative_options" ).length == 0 && $( ".avalon-player" ).length !== 0 ) {
      $( "#searchField" ).on( "keydown", function( e ) {
	if ( e.keyCode == 9 ) {
          tabIntoPlayer( e );
          if ( !e.shiftKey ) {
            return false;
          }
	}
      });
    } else {
      $( "#administrative_options a:last" ).on( "keydown", function( e ) {
        if ( e.keyCode == 9 ) {
          tabIntoPlayer( e );
          if ( !e.shiftKey ) {
            return false;
          }
	}
      });
    }

    $( "#share-button a:first" ).on( "keydown", function( e ) {
      if ( e.shiftKey && e.keyCode == 9 ) {
        $( ".mejs-controls" ).css( "visibility", "visible" );
        $( ".mejs-controls button:last" ).focus()
        return false;
      }
    });

    // Hide the controls when tabbing out of the player
    $( ".mejs-controls button:last" ).on( "keydown", function( e ) {
      if ( !e.shiftKey && e.keyCode == 9 ) {
        $( ".mejs-controls" ).css( "visibility", "hidden" );
      }
    });

    $( ".mejs-controls button:first" ).on( "keydown", function( e ) {
      if ( e.shiftKey && e.keyCode == 9 ) {
        $( ".mejs-controls" ).css( "visibility", "hidden" );
      }
    });
  };
