  var avalonStartTime = 0;
  var avalonDuration = 0;
  var originalSetCurrentTime;
  var originalGetCurrentTime;

  function androidPrePlay(startTime, duration, player){
    avalonStartTime = startTime;
    avalonDuration = duration;
    originalSetCurrentTime = player.setCurrentTime;
    player.setCurrentTime = androidSetCurrentTime;
    //player.media.setCurrentTime = androidSetCurrentTime;
    originalGetCurrentTime = player.getCurrentTime;
    player.getCurrentTime = androidGetCurrentTime;
    player.media.addEventListener('play', androidFirstPlay, true);
  }
 
  function durationChanged () {
    console.log(currentPlayer.media.duration);
    if (currentPlayer.media.duration == 0)
      return;
    currentPlayer.setCurrentTime(avalonStartTime);
    console.log(currentPlayer.media.duration + " " + currentPlayer.getCurrentTime() + " " + currentPlayer.media.seeking);
    currentPlayer.media.removeEventListener('durationchange', durationChanged);
  }

  function androidSetCurrentTime (time) {
    //don't actually call media.currentTime but update everything else manually
    console.log('androidSetCurrentTime: ' + time);
    avalonStartTime = time;
    androidSetCurrentRail(time);
    androidUpdateCurrent(time);
    update_active_stream();
  }

  function androidGetCurrentTime () {
    return avalonStartTime;
  }

  function androidSetCurrentRail (time) {
    var total = currentPlayer.controls.find('.mejs-time-total');
    var handle = currentPlayer.controls.find('.mejs-time-handle');
    var current = currentPlayer.controls.find('.mejs-time-current');
    
    // update bar and handle
    if (total && handle) {
      var
        newWidth = Math.round(total.width() * time / avalonDuration),
        handlePos = newWidth - Math.round(handle.outerWidth(true) / 2);

        current.width(newWidth);
        handle.css('left', handlePos);
    }
  }

  function androidUpdateCurrent (time) {
    var currenttime = currentPlayer.currenttime;
    if (currenttime) {
      currenttime.html(mejs.Utility.secondsToTimeCode(time, currentPlayer.options.alwaysShowHours || avalonDuration > 3600, currentPlayer.options.showTimecodeFrameCount,  currentPlayer.options.framesPerSecond || 25));
    }
  }

  function androidFirstPlay () {
    currentPlayer.setCurrentTime = originalSetCurrentTime;
    //currentPlayer.media.setCurrentTime = originalSetCurrentTime;
    currentPlayer.getCurrentTime = originalGetCurrentTime;
    currentPlayer.media.addEventListener('durationchange', durationChanged, true);
    currentPlayer.media.removeEventListener("play", androidFirstPlay);
  }
