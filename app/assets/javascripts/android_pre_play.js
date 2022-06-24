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

(function() {
  var _t = {
    androidPrePlay: function(handler, player){
      _t.handler = handler;
      _t.player = player;
      _t.avalonStartTime = handler.stream_info.t || 0;
      _t.avalonDuration = handler.stream_info.duration;
      if (typeof _t.originalSetCurrentTime != 'function')
        _t.originalSetCurrentTime = _t.player.setCurrentTime;
      _t.player.setCurrentTime = _t.androidSetCurrentTime;
      if (typeof _t.originalGetCurrentTime != 'function')
        _t.originalGetCurrentTime = _t.player.getCurrentTime;
      _t.player.getCurrentTime = _t.androidGetCurrentTime;
      $(_t.player.durationD).html(mejs.Utility.secondsToTimeCode(parseInt(handler.stream_info.duration)));
      _t.player.media.addEventListener('play', _t.androidFirstPlay, true);
    },

    durationChanged: function() {
      console.log(_t.player.media.duration);
      if (_t.player.media.duration == 0)
        return;
      _t.player.setCurrentTime(_t.avalonStartTime);
      console.log(_t.player.media.duration + " " + _t.player.getCurrentTime() + " " + _t.player.media.seeking);
      _t.player.media.removeEventListener('durationchange', _t.durationChanged);
    },

    androidSetCurrentTime: function(time) {
      //don't actually call media.currentTime but update everything else manually
      console.log('androidSetCurrentTime: ' + time);
      _t.avalonStartTime = time;
      _t.androidSetCurrentRail(time);
      _t.androidUpdateCurrent(time);
      _t.handler.setActiveSection();
    },

    androidGetCurrentTime: function() {
      return _t.avalonStartTime;
    },

    androidSetCurrentRail: function(time) {
      var total = _t.player.controls.find('.mejs-time-total');
      var handle = _t.player.controls.find('.mejs-time-handle');
      var current = _t.player.controls.find('.mejs-time-current');

      // update bar and handle
      if (total && handle) {
        var
          newWidth = Math.round(total.width() * time / _t.avalonDuration),
          handlePos = newWidth - Math.round(handle.outerWidth(true) / 2);

          current.width(newWidth);
          handle.css('left', handlePos);
      }
    },

    androidUpdateCurrent: function(time) {
      var currenttime = _t.player.currenttime;
      if (currenttime) {
        currenttime.html(mejs.Utility.secondsToTimeCode(time, _t.player.options.alwaysShowHours || _t.avalonDuration > 3600, _t.player.options.showTimecodeFrameCount,  _t.player.options.framesPerSecond || 25));
      }
    },

    androidFirstPlay: function() {
      _t.player.setCurrentTime = _t.originalSetCurrentTime;
      //_t.player.media.setCurrentTime = originalSetCurrentTime;
      _t.player.getCurrentTime = _t.originalGetCurrentTime;
      _t.player.media.addEventListener('durationchange', _t.durationChanged, true);
      _t.player.media.removeEventListener("play", _t.androidFirstPlay);
    }
  };

  (typeof exports !== "undefined" && exports !== null ? exports : this).AndroidShim = _t;
})();
