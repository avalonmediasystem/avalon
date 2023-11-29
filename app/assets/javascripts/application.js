/*
 * Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require rails-ujs

// Required by Blacklight
//= require popper
//= require twitter/typeahead
//= require bootstrap
//= require jquery-ui
//= require blacklight/blacklight
//= require browse_everything
//= require modernizr
//= require bootstrap-toggle
//= require cropperjs/dist/cropper.min
//= require url-search-params-polyfill/index.js

//= require moment/min/moment-with-locales.min.js
//= require hls.js/dist/hls.min.js

// include all of our vendored js
//= require_tree ../../../vendor/assets/javascripts/.

// Require VideoJS and VideoJS quality selector for embedded player
//= require video.js/dist/video.min.js
//= require @silvermine/videojs-quality-selector/dist/js/silvermine-videojs-quality-selector.min.js

//= require_tree .
