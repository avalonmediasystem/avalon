# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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
      target = $(".progress-bar.bg-#{type}",bar)
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
      section_node = $(sec).closest('.card-title')
      bar = section_node.find('span.progress')
      info_box = section_node.find('div.alert')

      info = @data[id]
      if info?
        setActive(bar, info.complete < 100 and (info.status == 'RUNNING' or info.status == 'WAITING'))

        info_box.html(info.operation) if info.operation?
        if info.complete == 100
          info_box.html(info.status)
        updateBar(bar, {success: info.success, danger: info.error})
        if info.status == 'FAILED'
          info_box.html("ERROR: #{info.message}")
          info_box.addClass('alert-error')
          info_box.show()
#          else
#            updateBar(bar, 'bar-warning', 100)
        bar.data('status',info)

    if !info?
      info = @data['overall']
      setActive($('#overall'), info.success + info.error < 100)

      updateBar($('#overall'), {success: info.success, danger: info.error})
      $('#overall').data('status',info)
      if info.success == 100
        location.reload()

      return info.success + info.error < 100

$(document).ready ->
  if $('.progress-bar').length == 0
    return

  progress_controller = new AvalonProgress()

  $('.progress-indented').prepend('
    <span class="progress progress-inline">
      <div class="progress-bar bg-success" style="width:0%"></div>
      <div class="progress-bar bg-danger" style="width:0%"></div>
      <div class="progress-bar bg-warning" style="width:0%"></div>
    </span>')
  $('.status-detail').hide()
  progress_controller.retrieve(true)
  $('.progress-inline').click ->
    $(this).nextAll('.status-detail').slideToggle()
