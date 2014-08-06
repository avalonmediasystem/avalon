/* 
 * Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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

// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= stub hydra/hydra-head
//
//= require fix_console
//= require jquery
//= require jquery_ujs
//= require blacklight/blacklight

// Let's be selective on which modules we include instead of going down the 
// kitchen sink route. Even some of these may not be needed down the road.
//
// Required by Blacklight
//= require jquery-ui
//= require jquery.ui.nestedSortable

//= require bootstrap-sprockets


/* requirements for handling modals with modal logic gem */
//= require modal_logic
//= require handlebars.runtime
//= require templates/modal/crud

//= require browse_everything

/* bootstrap 3 eliminated typeahead. use twitter-typeahead-rails instead */
//= require twitter/typeahead

/*
 * Place any local overrides in avalon.js (for Blacklight, Hydra, jQuery,
 * etc) 
 */
//= require avalon
//= require pop_help
//= require access_autocomplete
//= require_self
