/* 
 * Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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
  Blacklight.do_search_context_behavior = function() {};

  $(document).on('click', '.btn-stateful-loading', function() {
    $(this).button('loading');
  });

  $('.popover-target').popover({
    placement: 'top',
    html: true,
    trigger: 'hover',
    delay: { show: 250, hide: 500 },
    content: function() {
      return $(this)
        .next('.po-body')
        .html();
    }
  });

  $('#show_object_tree').on('click', function() {
    var ot = $('#object_tree');
    ot.load(ot.data('src'));
    // return false;
  });

  var iOS = !!/(iPad|iPhone|iPod)/g.test(navigator.userAgent);
  if (iOS) {
    $('input[readonly], textarea[readonly]').on('cut paste keydown', function(
      e
    ) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    });
    $('input[readonly], textarea[readonly]').attr('readonly', false);
  }

  $('a')
    .has('img, ul')
    .addClass('block');

  window.addEventListener(
    'hashchange',
    function(event) {
      var element = document.getElementById(location.hash.substring(1));
      if (element) {
        if (!/^(?:a|select|input|button|textarea)$/i.test(element.tagName)) {
          element.tabIndex = -1;
        }
        element.focus();
      }
    },
    false
  );

  $('#content').focus(function() {
    $('.mejs-controls').css('visibility', 'visible');
    $('.mejs-controls button:first').focus();
  });

  // Set CSS to push the page content above footer
  $('.content-wrapper').css('padding-bottom', $('#footer').css('height'));

  /* Toggle CSS classes for global search form */
  const $searchWrapper = $('.global-search-wrapper');
  const $searchSubmit = $('.global-search-submit');

  // Remove CSS classes at initial page load for mobile screens
  if ($(window).width() < 768) {
    $searchWrapper.removeClass('input-group-lg');
    $searchSubmit.removeClass('btn-primary');
  }

  // Toggle CSS classes when window resizes
  $(window).resize(function() {
    if ($(window).width() < 768) {
      if ($searchWrapper.hasClass('input-group-lg')) {
        $searchWrapper.removeClass('input-group-lg');
      }
      if ($searchSubmit.hasClass('btn-primary')) {
        $searchSubmit.removeClass('btn-primary');
      }
    } else {
      $searchWrapper.addClass('input-group-lg');
      $searchSubmit.addClass('btn-primary');
    }
  });
});
