// Copyright 2011-2025, The Trustees of Indiana University and Northwestern
//   University.  Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.

// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
//   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied. See the License for the
//   specific language governing permissions and limitations under the License.
// ---  END LICENSE_HEADER BLOCK  ---

$(function() {
  const add_button_html = '<button type="button" class="add-dynamic-field btn btn-outline btn-light"><span class="fa fa-plus"></span></button>';
  const remove_button_html = '<button type="button" class="remove-dynamic-field btn btn-outline btn-light"><span class="fa fa-minus"></span></button>';
  
  $('.mb-3.multivalued').each(function() {
    const t = $(this);
    t.find('.input-group').each(function(igIndex, e) {
      $(e).find('input[id]').each((inIndex, e2) => e2.id = e2.id + igIndex);
      //Update typeahead targets
      return $(e).find('input[data-bs-target]').each((inIndex, e2) => $(e2).attr('data-bs-target', $(e2).attr('data-bs-target') + igIndex));
    });
    t.find('.input-group:not(:last)').append(remove_button_html);
    return t.find('.input-group:last').append(add_button_html);
  });

  $(document).on('click', '.add-dynamic-field', function(e) {
    e.preventDefault();
    const current_input_group = $(this).closest('.input-group');
    const new_input_group = current_input_group.clone();
    new_input_group.find('input, textarea').val('');
    new_input_group.find('input[id], textarea[id]').each(function(i,e) {
      const idArray = e.id.split('_');
      idArray.push(parseInt(idArray.pop()) + 1);
      return e.id = idArray.join('_');
    });
    new_input_group.find('input[data-bs-target], textarea[data-bs-target]').each(function(i, e) {
      const target = $(e).attr('data-bs-target').split('_');
      target.push(parseInt(target.pop()) + 1);
      return $(e).attr('data-bs-target', target.join('_'));
    });
    if (current_input_group.find('.typeahead').length) {
      current_input_group.find('.typeahead').attr('open', false);
      const new_autocomplete = new_input_group.find('.typeahead');
      const for_attr = new_autocomplete.attr('for');
      let target = for_attr.split('-')[0].split('_');
      target.push(parseInt(target.pop()) + 1);
      target = target.join('_');
      new_autocomplete.attr('for', target + '-popup');
      const ul = new_autocomplete.find(".autocomplete_popup");
      ul.attr('id', target + '-popup');
      const feedback = new_autocomplete.find(".autocomplete_feedback");
      feedback.attr('id', target + '-popup-feedback');
    } else if (current_input_group.find('.dropdown-menu').length) {
      const dropdown_default_label = current_input_group.find('.dropdown-menu li:first a').text();
      const dropdown_default_value = current_input_group.find('.dropdown-menu li:first span').text();
      new_input_group.find('.dropdown-toggle span').first().text(dropdown_default_label);
      new_input_group.find('input[type="hidden"]').val(dropdown_default_value);
    }
    current_input_group.find('button.add-dynamic-field').remove();
    current_input_group.append(remove_button_html);
    const textarea = current_input_group.data('textarea');
    if (typeof(textarea) !== "undefined") {
      const current_textarea = $(document.getElementById(textarea));
      const new_textarea = current_textarea.clone();
      new_textarea.val('');
      const idArray = new_textarea.attr('id').split('_');
      idArray.push(parseInt(idArray.pop()) + 1);
      new_textarea.attr('id', idArray.join('_'));
      new_input_group.attr('data-textarea', new_textarea.attr('id'));
      current_textarea.after(new_input_group);
      return new_input_group.after(new_textarea);
    } else {
      return current_input_group.after(new_input_group);
    }
  });
        
  return $(document).on('click', '.remove-dynamic-field', function(e) {
    e.preventDefault();
    const current_input_group = $(this).closest('.input-group');
    const textarea = current_input_group.data('textarea');
    if (typeof(textarea)!=="undefined") {
      $(document.getElementById(textarea)).remove();
    }
    return current_input_group.remove();
  });
});
