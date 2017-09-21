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

// include all of our vendored js
//= require_tree ../../../vendor/assets/javascripts/.

// Exclude MediaElement 4 JS files in /vendor, as ME4 collides with the ME2 gem
//= stub mediaelement/mediaelement-and-player
//= stub mediaelement/plugins/markers
//= stub mediaelement/plugins/quality
//= stub mediaelement/plugins/quality-i18n
//= stub media_player_wrapper/mejs4_add_to_playlist

//= require_tree .
