# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

class AvalonProgress
  setActive = (target, active) -> 
    if active then target.addClass('progress-striped active') else target.removeClass('progress-striped active')

  updateBar = (bar, attrs) -> 
    for type, percent of attrs
      target = $(".bar.bar-#{type}",bar)
      target.css('width',"#{percent}%")

  retrieve: (auto=false) ->
    $.ajax $('#progress').data('progress-url'),
      dataType: 'json',
      success: (data) => 
        @data = data
        if @update() and auto
          setTimeout =>
            @retrieve(auto)
          , 10000

  data: {}

  update: ->
    sections = $('a[data-segment]')
    sections.each (i,sec) =>
      id = $(sec).data('segment')
      bar = $(sec).prev('span.progress')
      info_box = $(sec).next('div.alert')

      info = @data[id]
      
      if info?
        setActive(bar, info.complete < 100 and (info.status == 'RUNNING' or info.status == 'WAITING'))

        info_box.html(info.operation) if info.operation?
        updateBar(bar, {success: info.success, danger: info.error})
        if info.status == 'FAILED'
          info_box.html("ERROR: #{info.message}")
          info_box.addClass('alert-error')
          info_box.show()
#          else
#            updateBar(bar, 'bar-warning', 100)
        bar.data('status',info)

    info = @data['overall']
    setActive($('#overall'), info.success + info.error < 100)

    updateBar($('#overall'), {success: info.success, danger: info.error})
    $('#overall').data('status',info)
    return info.success + info.error < 100

  click_section: (section_id) ->
    data = @data[section_id]
    if data.status != 'SUCCEEDED' or data.complete < 100
      window.currentPlayer = null
      $('#player').html('<div id="nojs"></div>')

$(document).ready ->
  progress_controller = new AvalonProgress()

  $('.status-detail').hide()
  progress_controller.retrieve(true)
  $('.progress-inline').click ->
    $(this).nextAll('.status-detail').slideToggle()

  $('a[data-segment]').bind 'streamswitch', ->
    progress_controller.click_section($(this).data('segment'))
