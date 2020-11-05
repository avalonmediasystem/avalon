# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---



class AvalonPlayer
  constructor: (container, stream_info, opts) ->
    @container = container
    element = @container.find('video,audio')
    @stream_info = stream_info
    removeOpt = (key) -> value = opts[key]; delete opts[key]; value
    thumbnail_selector = if removeOpt('thumbnailSelector') then 'thumbnailSelector' else null
    add_to_playlist = if removeOpt('addToPlaylist') then 'addToPlaylist' else null
    display_track_scrubber = if removeOpt('displayTrackScrubber') then 'trackScrubber' else null
    add_marker = if removeOpt('addMarker') then 'addMarkerToPlaylistItem' else null
    start_time = removeOpt('startTime')
    success_callback = removeOpt('success')

    features = ['playpause', 'current','progress','duration',display_track_scrubber,'volume','tracks','qualities',thumbnail_selector, add_to_playlist, add_marker, 'fullscreen','responsive']
    features = (feature for feature in features when feature?)
    player_options =
      mode: 'auto_plugin'
      usePluginFullScreen: false
      thumbnailSelectorUpdateURL: '/update-url'
      thumbnailSelectorEnabled: true
      addToPlaylistEnabled: true
      addMarkerToPlaylistItemEnabled: true
      trackScrubberEnabled: display_track_scrubber == 'trackScrubber'
      features: features
      startQuality: 'low'
      customError: 'This browser requires Adobe Flash Player to be installed for media playback.'
      toggleCaptionsButtonWhenOnlyOne: 'true'
      success: (mediaElement, domObject, player) =>
        @boundPrePlay = => if mejs.MediaFeatures.isAndroid then AndroidShim.androidPrePlay(this, player)
        @boundPrePlay()
        if success_callback then success_callback(mediaElement, domObject, player)

    player_options[key] = val for key, val of opts
    @player = new MediaElementPlayer element, player_options
    @refreshStream()
    $(document).ready => @initStructureHandlers()

  setupCreationTrigger: ->
    watchForCreation = =>
      # Special case visibility trigger for IE
      if (mejs.PluginDetector.ua.match(/trident/gi) != null) then @container.find('#content').css('visibility','visible')

      if @player? && @player.created? && @player.created
        $(@player).trigger('created')
      else
        setTimeout(watchForCreation, 100);
    watchForCreation()

  refreshStream: ->
    if @stream_info? && @player?
      @player.pause()
      videoNode = $(@player.$node)
      videoNode.html('')
      $('.scrubber-marker').remove()
      $('.mejs-time-clip').remove()

      for hls in @stream_info.stream_hls
        videoNode.append "<source src='#{hls.url}' data-quality='#{hls.quality}' data-plugin-type='native' type='application/vnd.apple.mpegURL'>"
      if @stream_info.captions_path
        videoNode.append "<track srclang='en' kind='subtitles' type='#{ @stream_info.captions_format }' src='#{ @stream_info.captions_path }'></track>"

      if @stream_info.poster_image? then @player.setPoster(@stream_info.poster_image)
      initialTime = if @stream_info.t? then (parseFloat(@stream_info.t)||0) else 0
      if @player.qualities? && @player.qualities.length > 0
        @player.buildqualities(@player, @player.controls, @player.layers, @player.media)

      initialize_view = =>
        if _this.stream_info.hasOwnProperty('t') and _this.player.options.displayMediaFragment
          duration = _this.stream_info.duration
          t = _this.stream_info.t
          start_percent = Math.round(if isNaN(parseFloat(t[0])) then 0 else (100*parseFloat(t[0]) / duration))
          start_percent = Math.max(0,Math.min(100,start_percent));
          end_percent = Math.round(if t.length < 2 or isNaN(parseFloat(t[1])) then 100 else (100*parseFloat(t[1]) / duration))
          end_percent = Math.max(0,Math.min(100,end_percent));
          clip_span = $('<span />').addClass('mejs-time-clip')
          clip_span.css 'left', start_percent+'%'
          clip_span.css 'width', end_percent-start_percent+'%'
          $('.mejs-time-total').append clip_span
        if _this.player.options.displayMarkers
          duration = _this.stream_info.duration
          scrubber = $('.mejs-time-rail')
          total = $('.mejs-time-total')
          scrubber.css('position', 'relative')
          marker_rail = $('<span  class="mejs-time-marker-rail">')
          $('.row.marker').each (i,value) ->
            offset = $(this)[0].dataset['offset']
            marker_id = $(this)[0].dataset['marker']
            title = String($(this).find('.marker_title')[0].text).replace(/"/g, '&quot;') + " ["+mejs.Utility.secondsToTimeCode(offset)+"]"
            offset_percent = if isNaN(parseFloat(offset)) then 0 else Math.min(100,Math.round(100*offset / duration))
            marker = $('<span class="fa fa-chevron-up scrubber-marker" style="left: '+offset_percent+'%" data-marker="'+marker_id+'"></span>')
            marker.click (e) ->
              currentPlayer.setCurrentTime offset
            marker_rail.append(marker)
            marker_rail.append('<span class="mejs-time-float-marker" data-marker="'+marker_id+'" style="display: none; left: '+offset_percent+'%" ><span class="mejs-time-float-current-marker">'+title+'</span><span class="mejs-time-float-corner-marker"></span></span>')
          scrubber.append(marker_rail)
          _this.player.globalBind('resize', (e) ->
            marker_rail.width(total.width())
          )
          marker_rail.width(total.width())
          $('.scrubber-marker').bind('mouseenter', (e) ->
            $('.mejs-time-float-marker[data-marker="'+this.dataset.marker+'"]').show()
          ).bind 'mouseleave', (e) ->
            $('.mejs-time-float-marker[data-marker="'+this.dataset.marker+'"]').hide()
        @player.setCurrentTime initialTime

      @player.options.playlistItemDefaultTitle = @stream_info.embed_title

      $(@player).one 'created', =>

        $(@player.media).on 'timeupdate', =>
          @setActiveSection()
        @container.find('#content').css('visibility','visible')
        @player.setCurrentTime(initialTime)

        #Save because it might be necessary if showing mediafragment of object without structure...
        if @player.options.trackScrubberEnabled
          if _this.stream_info.hasOwnProperty('t')
            trackstart = _this.stream_info.t[0]
            trackend = _this.stream_info.t[1] || _this.stream_info.duration
          else
            trackstart = 0
            trackend = _this.stream_info.duration
          @player.initializeTrackScrubber(trackstart, trackend, _this.stream_info)
          $(@player.media).on 'timeupdate', =>
            @player.updateTrackScrubber()
          @player.globalBind('resize', (e) ->
            _this.player.resizeTrackScrubber()
          )
        $(@player.media).one 'loadedmetadata', initialize_view
        $(@player.media).one 'loadeddata', initialize_view
        # in case media is not playable yet, also listen for canplay
        $(@player.media).one 'canplay', =>
          if @player.options.autostart
            @player.media.play()
        keyboardAccess()
        @boundPrePlay()
        if @player.options.autostart
          @player.media.play()

      @player.load()
      @setupCreationTrigger()
      @player.cleartracks(@player, null, null, null)
      @player.rebuildtracks()


  setStreamInfo: (value) ->
    @stream_info = value
    @refreshStream()

  setActiveSection: ->
    if @active_segment != @stream_info.id
      @active_segment = @stream_info.id
      @container.find("a.current-section").removeClass('current-section')
      @container.find("a[data-segment='#{@active_segment}']:first").addClass('current-section')

    section_nodes = @container.find("a[data-segment='#{@active_segment}'].playable")
    current_time = if @player? then @player.getCurrentTime() else 0
    active_node = null
    for node in section_nodes by -1
      node_data = $(node).data()
      begin = parseFloat(node_data.fragmentbegin) || 0
      end = parseFloat(node_data.fragmentend) || Number.MAX_VALUE
      if (begin <= current_time <= end)
        active_node = node
        break
#    active_node ||= $('a.current-section')

    current_stream = @container.find('a.current-stream')
    if current_stream[0] != active_node
      current_stream.removeClass('current-stream')
      $(active_node)
        .addClass('current-stream')
        .trigger('streamswitch', [@stream_info])
      if @player? && @player.options.trackScrubberEnabled && active_node!=null
        trackstart = parseFloat($(active_node).data('fragmentbegin')||0)||0
        trackend = parseFloat($(active_node).data('fragmentend')||@stream_info.duration)||@stream_info.duration
        @player.initializeTrackScrubber(trackstart, trackend, @stream_info)

    marked_node = @container.find('i.now-playing')
    now_playing_node = @container.find('a.current-stream')
    if now_playing_node.length == 0
      now_playing_node = @container.find('a.current-section')
    unless now_playing_node == marked_node
      marked_node.remove()
      now_playing_node.before('<i class="now-playing fa fa-arrow-circle-right"></i>')

  initStructureHandlers: ->
    @container.find('a[data-segment]').on 'click', (e) =>
      target = $(e.currentTarget)
      segment = target.data('segment')

      current_stream =
        @container.find('a.current-stream').data() ||
        @container.find('a.current-section').data() ||
        {}
      target_stream  = target.data()

      if current_stream.isVideo == target_stream.isVideo
        e.preventDefault()
        if current_stream.segment == target_stream.segment
          @player.setCurrentTime(parseFloat(target.data('fragmentbegin')))
        else
          $('.mejs-overlay-loading').show().closest('.mejs-layer').show()
          splitUrl = (target_stream.nativeUrl || target.attr('href')).split('?')
          uri = "#{splitUrl[0]}/stream"
          params = ["content=#{segment}"]
          params.push(splitUrl[1]) if splitUrl[1]?
          autostart = @player.options.autostart
          $.getJSON uri, params.join('&'), (data) =>
            @player.options.autostart = autostart
            @setStreamInfo(data)
      else
        e.target.click()
      return

(exports ? this).AvalonPlayer = AvalonPlayer
