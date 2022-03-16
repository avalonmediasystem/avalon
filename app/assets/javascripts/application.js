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
//= require jquery_ujs

// Required by Blacklight
//= require jquery-ui
//= require blacklight/blacklight
//= require browse_everything
//= require modernizr
//= require bootstrap-toggle
//= require cropperjs/dist/cropper.min
//= require url-search-params-polyfill/index.js

//= require hls.js/dist/hls.min.js

// include all of our vendored js
//= require_tree ../../../vendor/assets/javascripts/.

// Exclude MediaElement 4 JS files in /vendor, as ME4 collides with the ME2 gem
//= stub mediaelement/mediaelement-and-player
//= stub mediaelement/plugins/markers
//= stub mediaelement/plugins/quality-avalon
//= stub mediaelement/plugins/quality-i18n
//= stub media_player_wrapper/mejs4_plugin_add_to_playlist
//= stub media_player_wrapper/mejs4_plugin_add_marker_to_playlist
//= stub media_player_wrapper/mejs4_plugin_create_thumbnail
//= stub media_player_wrapper/mejs4_plugin_track_scrubber
//= stub media_player_wrapper/mejs4_link_back
//= stub media_player_wrapper/mejs4_plugin_playlist_items

//= require_tree .
