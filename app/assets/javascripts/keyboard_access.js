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

$(document).ready(function() {
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
