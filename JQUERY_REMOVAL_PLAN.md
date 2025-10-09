# jQuery Removal Plan for Avalon Media System

## Overview

This document outlines the comprehensive plan for removing `jquery-rails` and `jquery-ui-rails` gems from the Avalon Media System. Currently, jQuery is heavily used across ~27 JavaScript files and ~10 ERB view templates.

**Current Status:** jQuery is required by:
- Gemfile lines 22-23: `jquery-rails` and `jquery-ui-rails`
- application.js lines 29, 35: jQuery and jQuery UI

## Critical Dependencies Analysis

### Third-Party Gems That May Require jQuery

#### 1. **Blacklight (~8.10)** ⚠️
- **Location:** Gemfile line 42
- **Purpose:** Search and catalog functionality
- **Status:** MUST VERIFY - May require jQuery
- **Action Required:** Check Blacklight 8.10 documentation
- **Alternative:** Upgrade to Blacklight 9+ (if jQuery-free)

#### 2. **BrowseEverything** 🚨
- **Location:** Gemfile line 75, used in `file_browse.js`
- **Purpose:** File browser for selecting files from cloud storage
- **Status:** MUST VERIFY - Likely requires jQuery
- **Action Required:** Check browse-everything gem documentation
- **Risk:** File upload from Dropbox/cloud storage may break
- **Alternative:** Find jQuery-free file browser gem OR keep jQuery

#### 3. **Bootstrap 5** ✅
- **Status:** Uses vanilla JavaScript (no jQuery required)
- **Note:** Already jQuery-independent

#### 4. **rails-ujs** ✅
- **Status:** Keep for AJAX form handling
- **Note:** Provides `ajax:success`, `ajax:error` events without jQuery

## Files Requiring Changes

### JavaScript Files (27 total)

#### Already Converted ✅ (2 files)

1. ✅ **file_upload_step.js**
   - Status: Converted to vanilla JS
   - Changes: Removed jQuery selectors, event handlers

2. ✅ **access_control_step.js**
   - Status: Converted to vanilla JS with js-datepicker
   - Changes: MutationObserver for dynamic content, date range validation

#### High Priority - Heavy jQuery Usage ❌ (11 files)

3. **avalon.js**
   ```javascript
   // jQuery usage:
   - $(document).ready()
   - Blacklight.do_search_context_behavior (may need jQuery)
   - $(document).on() event delegation
   - $('.btn-stateful-loading').button('loading')
   - $('#show_object_tree').on()
   - $('input[readonly]').on()
   - $('a').has('img, ul').addClass()
   ```

4. **player_listeners.js**
   ```javascript
   // jQuery usage:
   - $('#selector').collapse() - Bootstrap collapse API
   - $.ajax() - AJAX requests
   - $('form').serialize()
   - $(element).find()
   - Modal operations
   ```

5. **ramp_utils.js**
   ```javascript
   // jQuery usage:
   - DOM traversal with $()
   - $.ajax() for add to playlist
   - $('.collapse').collapse()
   - Form manipulation with $()
   - Event delegation
   ```

6. **add-playlist-option.js**
   ```javascript
   // jQuery usage:
   - Tom-select integration
   - Event handlers with .on()
   - $('#playlist_form').bind('ajax:success')
   - $(this) references
   ```

7. **move_section.js**
   ```javascript
   // jQuery usage:
   - $('#move_modal').on('shown.bs.modal')
   - $.ajax() requests
   - $('form').serialize()
   - Modal manipulation
   ```

8. **supplemental_files.js**
   ```javascript
   // jQuery usage:
   - $(document).on() event delegation
   - .on('ajax:success', 'ajax:error')
   - localStorage with accordion state
   - $('.collapse').collapse()
   ```

9. **avalon_progress.js**
   ```javascript
   // jQuery usage:
   - $.ajax() for polling
   - $('.progress-bar') updates
   - $(document).ready()
   ```

10. **dynamic_fields.js**
    ```javascript
    // jQuery usage:
    - $(element).clone()
    - .on('click') event delegation
    - .closest() DOM traversal
    - .remove() element removal
    ```

11. **file_browse.js** 🚨 CRITICAL
    ```javascript
    // jQuery usage:
    - $('#browse-btn').browseEverything() - GEM PLUGIN
    - $(this).closest('form').submit()
    - $(document).on() event delegation
    - Bootstrap Modal with $()
    ```
    **Note:** BrowseEverything gem plugin may REQUIRE jQuery

12. **button_confirmation.js**
    ```javascript
    // jQuery usage:
    - Mixed vanilla/jQuery
    - Bootstrap Popover API
    - $(document).on()
    ```

13. **avalon_playlists/playlists.js**
    ```javascript
    // jQuery usage:
    - $('.copy-playlist-button').on('click')
    - $('#copy-playlist-modal').modal()
    - .find(), .val(), .prop()
    - $('#copy-playlist-form').bind('ajax:success', 'ajax:error')
    ```

#### Medium Priority ❌ (10 files)

14. **avalon_timelines/timelines.js** - Similar to playlists.js
15. **sessions_new.js** - Event delegation, CSS manipulation
16. **select_all.js** - Checkbox operations, window.onbeforeunload
17. **pop_help.js** - Tooltip/collapse, equal heights
18. **localize_times.js** - Element iteration, data attributes
19. **intercom_push.js** - Modal events, AJAX, select population
20. **import_button.js** - Bootstrap Popover, form operations
21. **crop_upload.js** - Mixed jQuery/vanilla, Cropper.js
22. **blacklight/modal_patch.js** - Minimal jQuery (mostly vanilla)
23. **blacklight/facet_load.js** - jQuery wrapper function

#### Low Priority / Vendor Files

24. **vendor/assets/javascripts/xmleditor/jquery.xmleditor.js**
    - **DO NOT MODIFY** - Third-party vendor file

### ERB View Templates with Inline jQuery (10+ files)

1. **app/views/playlists/_share.html.erb**
   - jQuery: `$(document).ready()`, `.on('click')`, `.tab('show')`, `.toggleClass()`

2. **app/views/playlists/_action_buttons.html.erb**
   - jQuery: `$(document).ready()`

3. **app/views/playlists/_show_playlist_details.html.erb**
   - jQuery: `$('#playlist-share-btn').click()`, `$.ajax()`

4. **app/views/playlists/index.html.erb**
   - jQuery: `$(this).closest('form')`, `$('.filedata').change()`

5. **app/views/playlists/_edit_form.html.erb**
   - Heavy jQuery: Multiple click handlers, `.val()`, `.prop()`, `.data()`

6. **app/views/timelines/_show_timeline_details.html.erb**
   - jQuery: Click handlers, AJAX, `.collapse()`

7. **app/views/timelines/show.html.erb**
   - jQuery: `$(document).ready()`, CSS manipulation

8. **app/views/timelines/index.html.erb**
   - jQuery: Form operations, file input

9. **app/views/media_objects/_structure.html.erb**
   - jQuery: (if present - needs verification)

10. **app/views/media_objects/_item_view.html.erb**
    - jQuery: (if present - needs verification)

11. **app/views/modules/_flash_messages.html.erb**
    - jQuery: `$('#cookieless').css("display", "block")`

## Conversion Strategies

### jQuery → Vanilla JS Quick Reference

| Operation | jQuery | Vanilla JS |
|-----------|--------|------------|
| **Selectors** | | |
| Single element | `$('#id')` | `document.getElementById('id')` or `document.querySelector('#id')` |
| Multiple elements | `$('.class')` | `document.querySelectorAll('.class')` |
| Find within | `$(parent).find('.child')` | `parent.querySelectorAll('.child')` |
| Closest parent | `$(el).closest('.parent')` | `el.closest('.parent')` |
| **Events** | | |
| Document ready | `$(document).ready(fn)` | `document.addEventListener('DOMContentLoaded', fn)` |
| Event listener | `$(el).on('click', fn)` | `el.addEventListener('click', fn)` |
| Event delegation | `$(doc).on('click', '.btn', fn)` | `document.addEventListener('click', e => { if(e.target.matches('.btn')) fn(e) })` |
| Trigger event | `$(el).trigger('event')` | `el.dispatchEvent(new Event('event'))` |
| **DOM Manipulation** | | |
| Get value | `$(el).val()` | `el.value` |
| Set value | `$(el).val('text')` | `el.value = 'text'` |
| Get attribute | `$(el).attr('name')` | `el.getAttribute('name')` |
| Set attribute | `$(el).attr('name', 'val')` | `el.setAttribute('name', 'val')` |
| Get data | `$(el).data('key')` | `el.dataset.key` |
| Add class | `$(el).addClass('cls')` | `el.classList.add('cls')` |
| Remove class | `$(el).removeClass('cls')` | `el.classList.remove('cls')` |
| Toggle class | `$(el).toggleClass('cls')` | `el.classList.toggle('cls')` |
| Has class | `$(el).hasClass('cls')` | `el.classList.contains('cls')` |
| CSS property | `$(el).css('prop', 'val')` | `el.style.prop = 'val'` |
| Get HTML | `$(el).html()` | `el.innerHTML` |
| Set HTML | `$(el).html('<p>text</p>')` | `el.innerHTML = '<p>text</p>'` |
| Get text | `$(el).text()` | `el.textContent` |
| Set text | `$(el).text('text')` | `el.textContent = 'text'` |
| Append | `$(parent).append(child)` | `parent.appendChild(child)` |
| Remove | `$(el).remove()` | `el.remove()` |
| Clone | `$(el).clone()` | `el.cloneNode(true)` |
| **Traversal** | | |
| Parent | `$(el).parent()` | `el.parentElement` |
| Children | `$(el).children()` | `el.children` |
| Siblings | `$(el).siblings()` | `Array.from(el.parentElement.children).filter(c => c !== el)` |
| First child | `$(el).children().first()` | `el.firstElementChild` |
| Last child | `$(el).children().last()` | `el.lastElementChild` |
| **Iteration** | | |
| Each | `$(els).each(function() {})` | `els.forEach(el => {})` |
| Map | `$(els).map(fn)` | `Array.from(els).map(fn)` |
| **AJAX** | | |
| GET request | `$.ajax({url, method:'GET'})` | `fetch(url).then(r => r.json())` |
| POST request | `$.ajax({url, method:'POST', data})` | `fetch(url, {method:'POST', body:data})` |
| Serialize form | `$(form).serialize()` | `new FormData(form)` |
| **Effects** | | |
| Show/Hide | `$(el).show() / .hide()` | `el.style.display = 'block' / 'none'` |
| Toggle | `$(el).toggle()` | `el.style.display = el.style.display === 'none' ? 'block' : 'none'` |
| **Bootstrap 5** | | |
| Modal show | `$(el).modal('show')` | `new bootstrap.Modal(el).show()` |
| Modal hide | `$(el).modal('hide')` | `bootstrap.Modal.getInstance(el).hide()` |
| Collapse toggle | `$(el).collapse('toggle')` | `new bootstrap.Collapse(el).toggle()` |
| Tab show | `$(el).tab('show')` | `new bootstrap.Tab(el).show()` |

### Rails UJS Event Conversion

```javascript
// OLD: jQuery UJS binding
$('#form').bind('ajax:success', function(event) {
  const [data, status, xhr] = Array.from(event.detail);
  console.log(data);
});

$('#form').bind('ajax:error', function(event) {
  const [data, status, xhr] = Array.from(event.detail);
  console.error(xhr.responseJSON);
});

// NEW: Vanilla JS with Rails UJS
document.getElementById('form').addEventListener('ajax:success', function(event) {
  const [data, status, xhr] = event.detail;
  console.log(data);
});

document.getElementById('form').addEventListener('ajax:error', function(event) {
  const [data, status, xhr] = event.detail;
  console.error(xhr.responseJSON);
});

// Event delegation approach
document.addEventListener('ajax:success', function(event) {
  if (event.target.matches('#form')) {
    const [data, status, xhr] = event.detail;
    console.log(data);
  }
});
```

## Implementation Plan

### Phase 0: Critical Investigation 🚨 **REQUIRED FIRST**

**DO NOT PROCEED** until these are verified:

1. **Check BrowseEverything jQuery Dependency**
   ```bash
   # Check gem documentation
   bundle info browse-everything
   # Look for jQuery requirements in gem source
   ```
   - If requires jQuery: Find alternative OR keep jQuery
   - If jQuery-free: Document version and continue

2. **Check Blacklight 8.10 jQuery Dependency**
   ```bash
   # Check gem documentation
   bundle info blacklight
   # Test search functionality without jQuery in dev environment
   ```
   - If requires jQuery: Consider upgrading to Blacklight 9+
   - If jQuery-free: Continue with confidence

3. **Decision Point:**
   - ✅ Both jQuery-free → Proceed with removal
   - ⚠️ One requires jQuery → Decide if functionality is worth keeping jQuery
   - 🚨 Both require jQuery → Strongly reconsider removing jQuery gems

### Phase 1: Simple Utility Files (Estimated: 4-6 hours)

Convert these files with straightforward jQuery usage:

1. **sessions_new.js**
   - Event delegation → `addEventListener`
   - CSS manipulation → `style` properties

2. **pop_help.js**
   - Tooltip/collapse → Bootstrap 5 vanilla APIs
   - Equal heights → Vanilla JS calculations

3. **localize_times.js**
   - `.each()` → `.forEach()`
   - `.data()` → `.dataset`
   - Moment.js integration (already vanilla)

4. **import_button.js**
   - Bootstrap Popover → vanilla API
   - Form operations → vanilla DOM

### Phase 2: Form Management Files (Estimated: 6-8 hours)

5. **dynamic_fields.js**
   - `.clone()` → `.cloneNode(true)`
   - Event delegation → vanilla events
   - `.remove()` → `.remove()`

6. **select_all.js**
   - Checkbox operations → vanilla properties
   - Window unload → vanilla event

7. **button_confirmation.js**
   - Bootstrap Popover → vanilla API
   - Event listeners → vanilla

### Phase 3: Progress & Polling Files (Estimated: 4-6 hours)

8. **avalon_progress.js**
   - `$.ajax()` → `fetch()`
   - Progress bar updates → vanilla DOM
   - Polling logic → `setInterval` with vanilla

### Phase 4: Complex Integration Files (Estimated: 12-16 hours)

9. **player_listeners.js** (Most complex)
   - Heavy refactor needed
   - Bootstrap collapse → vanilla API
   - AJAX → `fetch()`
   - Form serialization → `FormData`

10. **ramp_utils.js**
    - DOM traversal → vanilla selectors
    - AJAX → `fetch()`
    - Event management → vanilla

11. **move_section.js**
    - Modal operations → Bootstrap 5 vanilla
    - AJAX → `fetch()`
    - Form handling → vanilla

12. **supplemental_files.js**
    - Event delegation → vanilla
    - Rails UJS events → vanilla listeners
    - Accordion state → localStorage with vanilla

13. **avalon.js**
    - Blacklight integration (VERIFY jQuery not needed)
    - Event delegation → vanilla
    - Button states → vanilla

### Phase 5: Plugin Integration Files (Estimated: 8-12 hours)

14. **add-playlist-option.js**
    - Tom-select (already vanilla compatible)
    - Rails UJS events → vanilla

15. **avalon_playlists/playlists.js**
    - Modal operations → vanilla Bootstrap 5
    - Rails UJS → vanilla events
    - Form operations → vanilla

16. **avalon_timelines/timelines.js**
    - Similar to playlists

17. **intercom_push.js**
    - Modal events → vanilla
    - AJAX → `fetch()`

18. **crop_upload.js**
    - Cropper.js (already vanilla compatible)
    - Modal → vanilla Bootstrap 5

19. **file_browse.js** 🚨 **CRITICAL - VERIFY FIRST**
    - BrowseEverything plugin compatibility
    - May need to keep jQuery if plugin requires it

20. **blacklight/modal_patch.js**
    - Minimal changes (mostly vanilla already)

21. **blacklight/facet_load.js**
    - Remove jQuery wrapper

### Phase 6: ERB View Templates (Estimated: 8-12 hours)

Convert inline jQuery in all view templates:

22. **app/views/playlists/** (5 files)
    - _share.html.erb
    - _action_buttons.html.erb
    - _show_playlist_details.html.erb
    - index.html.erb
    - _edit_form.html.erb

23. **app/views/timelines/** (3 files)
    - _show_timeline_details.html.erb
    - show.html.erb
    - index.html.erb

24. **app/views/modules/** (1 file)
    - _flash_messages.html.erb

25. **app/views/media_objects/** (2 files - if applicable)
    - _structure.html.erb
    - _item_view.html.erb

### Phase 7: Final Cleanup & Testing (Estimated: 6-10 hours)

26. **Remove jQuery Dependencies**
    ```ruby
    # Gemfile changes
    - Remove: gem 'jquery-rails'
    - Remove: gem 'jquery-ui-rails'
    ```

27. **Update Application Manifest**
    ```javascript
    // app/assets/javascripts/application.js
    - Remove: //= require jquery
    - Remove: //= require jquery-ui
    - Keep: //= require rails-ujs
    ```

28. **Bundle Install**
    ```bash
    bundle install
    ```

29. **Comprehensive Testing**
    - Test all forms (submit, AJAX)
    - Test modals (show, hide, events)
    - Test file uploads
    - Test playlists functionality
    - Test timelines functionality
    - Test media player
    - Test search (Blacklight)
    - Test file browser (BrowseEverything)
    - Test access controls
    - Test all dynamic form fields
    - Run full RSpec suite
    - Run Cypress E2E tests

## Risk Assessment

### Critical Blockers 🚨

1. **BrowseEverything Gem**
   - **Risk:** May absolutely require jQuery
   - **Impact:** File upload from cloud storage breaks
   - **Mitigation:** Verify before starting, find alternative if needed

2. **Blacklight Gem**
   - **Risk:** May require jQuery for full functionality
   - **Impact:** Search/catalog features may break
   - **Mitigation:** Test thoroughly, consider upgrade to Blacklight 9+

### High Risks ⚠️

3. **Rails UJS Event Handling**
   - **Risk:** AJAX form submissions may break
   - **Impact:** Forms stop working silently
   - **Mitigation:** Update all `ajax:success`/`ajax:error` handlers

4. **Bootstrap Component Interactions**
   - **Risk:** Modal/collapse/tab behaviors may change
   - **Impact:** UI components malfunction
   - **Mitigation:** Use Bootstrap 5 vanilla APIs correctly

5. **Large Codebase Changes**
   - **Risk:** 27+ files to modify, high chance of bugs
   - **Impact:** Application instability
   - **Mitigation:** Convert incrementally, test after each file

### Medium Risks ⚙️

6. **Event Delegation Patterns**
   - **Risk:** Complex event delegation logic may break
   - **Impact:** Dynamic content stops responding to clicks
   - **Mitigation:** Test all dynamically added content

7. **DOM Traversal Changes**
   - **Risk:** `.closest()`, `.find()` behaviors slightly different
   - **Impact:** Element selection failures
   - **Mitigation:** Careful testing of all traversals

8. **Third-Party Library Integration**
   - **Risk:** Libraries expecting jQuery presence
   - **Impact:** Features break
   - **Mitigation:** Verify each library's dependencies

## Testing Checklist

### Functional Testing

- [ ] **Authentication & Authorization**
  - [ ] Login/logout
  - [ ] SAML authentication
  - [ ] LTI authentication
  - [ ] User permissions

- [ ] **Media Upload & Management**
  - [ ] Web upload
  - [ ] Dropbox upload (BrowseEverything)
  - [ ] File management
  - [ ] Section editing
  - [ ] Supplemental files

- [ ] **Search & Browse**
  - [ ] Blacklight search
  - [ ] Faceted search
  - [ ] Collection browsing
  - [ ] Bookmarks

- [ ] **Playlists**
  - [ ] Create playlist
  - [ ] Edit playlist
  - [ ] Add items to playlist
  - [ ] Copy playlist
  - [ ] Share playlist
  - [ ] Playlist visibility

- [ ] **Timelines**
  - [ ] Create timeline
  - [ ] Edit timeline
  - [ ] Copy timeline
  - [ ] Share timeline
  - [ ] Import timeline

- [ ] **Media Player**
  - [ ] Play/pause
  - [ ] Seek
  - [ ] Section switching
  - [ ] Add to playlist from player
  - [ ] Share buttons
  - [ ] Embed codes

- [ ] **Forms & Validation**
  - [ ] Date pickers
  - [ ] Dynamic fields
  - [ ] Access control forms
  - [ ] AJAX form submissions
  - [ ] Inline editing

- [ ] **Modals & Dialogs**
  - [ ] All modal open/close
  - [ ] Modal form submissions
  - [ ] Confirmation dialogs
  - [ ] Popovers

- [ ] **Admin Functions**
  - [ ] Collection management
  - [ ] User management
  - [ ] Batch operations
  - [ ] Bulk access control

### Automated Testing

- [ ] Run full RSpec test suite
  ```bash
  docker-compose exec test bash -c "bundle exec rspec"
  ```

- [ ] Run Cypress E2E tests
  ```bash
  docker-compose up cypress
  ```

- [ ] Check for JavaScript errors in browser console

### Browser Compatibility

- [ ] Chrome/Edge (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Mobile browsers

## Estimated Effort

### Total Time Estimate: 48-70 hours

- Phase 0: Investigation - 2-4 hours
- Phase 1: Simple files - 4-6 hours
- Phase 2: Form files - 6-8 hours
- Phase 3: Progress files - 4-6 hours
- Phase 4: Complex files - 12-16 hours
- Phase 5: Plugin files - 8-12 hours
- Phase 6: ERB templates - 8-12 hours
- Phase 7: Testing & cleanup - 6-10 hours

**Note:** Add 20-30% buffer for unexpected issues

## Decision Matrix

### Should You Remove jQuery?

| Factor | Keep jQuery | Remove jQuery |
|--------|-------------|---------------|
| BrowseEverything requires jQuery | ✅ | ❌ |
| Blacklight requires jQuery | ✅ | ❌ |
| Bundle size is critical | ❌ | ✅ |
| Have 60+ hours for conversion | ❌ | ✅ |
| Need modern codebase | ❌ | ✅ |
| Risk tolerance is low | ✅ | ❌ |
| Team familiar with vanilla JS | ❌ | ✅ |

## Recommendations

### Recommended Approach: Gradual Migration

Instead of removing jQuery gems immediately:

1. **Keep jQuery gems installed** (for now)
2. **Establish vanilla-JS-first policy** for new code
3. **Convert files incrementally** as they need maintenance
4. **Only remove gems when:**
   - ✅ 100% of custom code is jQuery-free
   - ✅ All gem dependencies verified jQuery-free
   - ✅ Full test coverage in place
   - ✅ Comprehensive testing completed

### Alternative: Minimal jQuery Build

If gems require jQuery:
1. Keep gems but use minimal jQuery build
2. Only load jQuery where absolutely needed
3. Continue migration of custom code

## Conclusion

Removing jQuery and jQuery UI gems from Avalon is a **significant undertaking** requiring careful planning, extensive testing, and potentially 50-70 hours of development time.

**Critical Success Factors:**
1. Verify BrowseEverything and Blacklight don't require jQuery
2. Convert code incrementally with thorough testing
3. Maintain comprehensive test coverage
4. Have rollback plan ready

**Before proceeding, complete Phase 0 investigation to confirm it's feasible.**

---

*Document Version: 1.0*
*Last Updated: 2025-10-13*
*Author: Claude Code Assistant*
