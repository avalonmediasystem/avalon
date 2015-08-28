# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
    start_time = removeOpt('startTime')
    
    features = ['playpause','current','progress','duration','volume','qualities',thumbnail_selector,'fullscreen','responsive']
    features = (feature for feature in features when feature?)
    player_options =
      mode: 'auto_plugin'
      pluginPath: '/assets/mediaelement_rails/'
      usePluginFullScreen: false
      thumbnailSelectorUpdateURL: '/update-url'
      thumbnailSelectorEnabled: true
      features: features
      startQuality: 'low'
      success: (mediaElement, domObject, player) =>
        @boundPrePlay = => if mejs.MediaFeatures.isAndroid then AndroidShim.androidPrePlay(this, player)
        @boundPrePlay()
        
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
      
      for flash in @stream_info.stream_flash
        videoNode.append "<source src='#{flash.url}' data-quality='#{flash.quality}' data-plugin-type='flash' type='video/rtmp'>"
      for hls in @stream_info.stream_hls
        videoNode.append "<source src='#{hls.url}' data-quality='#{hls.quality}' data-plugin-type='native' type='application/vnd.apple.mpegURL'>"

      if @stream_info.poster_image? then @player.setPoster(@stream_info.poster_image)
      initialTime = if @stream_info.t? then (parseFloat(@stream_info.t)||0) else 0
      if @player.qualities? && @player.qualities.length > 0
        @player.buildqualities(@player, @player.controls, @player.layers, @player.media)

      initialize_view = => @player.setCurrentTime(initialTime)

      $(@player).one 'created', =>
        $(@player.media).on 'timeupdate', => @setActiveSection()
        @container.find('#content').css('visibility','visible')
        @player.setCurrentTime(initialTime)
        $(@player.media).one 'loadedmetadata', initialize_view
        $(@player.media).one 'loadeddata', initialize_view
        keyboardAccess()
        @boundPrePlay()

        
      @player.load()
      @setupCreationTrigger()
        
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
          uri = "#{splitUrl[0]}.json"
          params = ["content=#{segment}"]
          params.push(splitUrl[1]) if splitUrl[1]?
          $.getJSON uri, params.join('&'), (data) => @setStreamInfo(data)
            
(exports ? this).AvalonPlayer = AvalonPlayer      
      
