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

// Store the previous active element before the popover is shown
let activeDeleteBtn = null;

// START: 'apply_button_confirmation' coffeescript to javascript conversion
$(function () {
  apply_button_confirmation();
});

window.apply_button_confirmation = function () {
  var btnList = [].slice.call(document.querySelectorAll('.btn-confirmation'))
  var popoverList = btnList.map(function(btn) {
    return new bootstrap.Popover(btn, {
      trigger: 'manual',
      html: true,
      sanitize: false,
      container: '#main-content',
      content: function () {
        let button;
        if (typeof $(this).attr('form') === "undefined") {
          button = '<a href="' + $(this).attr('href') + '" class="btn btn-sm btn-danger btn-confirm" role="button" data-method="delete" rel="nofollow" data-testid="table-view-delete-confirmation-btn">Yes, Delete</a>';
        } else {
          button = '<input class="btn btn-sm btn-danger btn-confirm" role="button" form="' + $(this).attr('form') + '" type="submit" value="Yes, Delete">';
          $('#' + $(this).attr('form')).find('[name="_method"]').val('delete');
        }
        return '<p>Are you sure?</p> ' + button + ' <a href="#" class="btn btn-sm btn-primary" role="button" id="special_button_color">No, Cancel</a>';
      }
    });
  });

  if (popoverList.length !== 0) {
    // Remove event before adding it to avoid duplicate event handling
    $(document).off('click', '#special_button_color');
    $(document).on('click', '#special_button_color', function (e) {
      // Stop page from scrolling up on 'Cancel' click
      e.preventDefault();
      // Restore focus to the active delete button
      if (activeDeleteBtn) {
        bootstrap.Popover.getInstance(activeDeleteBtn).hide();
        activeDeleteBtn.focus();
      }
      return true;
    });

    // Remove event before adding it to avoid duplicate event handling
    $(document).off('confirm', '.btn-confirmation')
    $(document).on('confirm', '.btn-confirmation', function(e) {
      if (activeDeleteBtn) {
        bootstrap.Popover.getInstance(activeDeleteBtn).hide();
      }
      bootstrap.Popover.getInstance(e.target).show();
      return false;
    });
  }
};
// END: 'apply_button_confirmation' coffeescript to javascript conversion

// After showing the popover, focus the first button inside it for keyboard accessibility
$(document).on('shown.bs.popover', '.btn-confirmation', function () {
  // Store the current delete button as the active delete button
  activeDeleteBtn = $(this);
  // Get the popover id
  let popoverId = $(this).attr('aria-describedby');
  if (popoverId) {
    let popover = $('#' + popoverId);
    let firstBtn = popover.find('.btn').first();
    if (firstBtn.length) {
      firstBtn.trigger('focus');
    }
  }
});

// Trap focus within the popover when it is opened
$(document).on('keydown', function (e) {
  // Only proceed if a popover is open
  let popoverIsOpen = $('.popover.show');
  if (popoverIsOpen) {
    // Find all focusable elements inside the popover
    let focusableEls = popoverIsOpen.find('a[role="button"]').filter(':visible');
    if (!focusableEls.length) return;

    let first = focusableEls[0];
    let last = focusableEls[focusableEls.length - 1];

    // Trap focus with Tab and Shift+Tab
    if (e.key === 'Tab') {
      let active = document.activeElement;
      if (e.shiftKey) {
        if (active === first) {
          e.preventDefault();
          last.focus();
        }
      } else {
        if (active === last) {
          e.preventDefault();
          first.focus();
        }
      }
    }
    // Close the popover when 'Esc' is pressed
    if (e.key === 'Escape') {
      e.preventDefault();
      $('.btn-confirmation').popover('hide');
      // Restore focus to the active delete button
      if (activeDeleteBtn) {
        bootstrap.Popover.getInstance(activeDeleteBtn).hide();
        activeDeleteBtn.focus();
      }
    }

  }
});
