class AvalonProgress
  @data = {}

  @retrieve = (auto=false) ->
    $.ajax $('#progress').data('progress-url'),
      dataType: 'json',
      success: (data) => 
        @data = data
        if @update() and auto
          setTimeout =>
            @retrieve(auto)
          , 10000

  @update = ->
    $('div.bar').remove()

    setActive = (target, active) -> 
      if active then target.addClass('progress-striped active') else target.removeClass('progress-striped active')
    addBar = (bar, type, percent) -> 
      bar.append "<div class='bar #{type}' style='width:#{percent}%'></div>"
        
    total = 0
    total_error = 0

    sections = $('a[data-segment]')
    sections.each ->
      id = $(this).data('segment')
      bar = $(this).prev('span.progress')
      data = AvalonProgress.data[id]
      
      if data?
        setActive(bar, data.complete < 100 and (data.status == 'RUNNING' or data.status == 'WAITING'))

        switch data.status
          when 'RUNNING', 'SUCCEEDED'
            total += Math.min(100,Math.ceil(data.complete / sections.length))
            addBar(bar, '', data.complete)
          when 'FAILED'
            total_error += (100 / sections.length)
            error = 100 - data.complete
            addBar(bar, '', data.complete)
            addBar(bar, 'bar-danger', error)
          else
            addBar(bar, 'bar-warning', 100)

    setActive($('#overall'), total + total_error < 100)
    $('#overall').append "<div class='bar' style='width: #{total}%'></div>"
    $('#overall').append "<div class='bar bar-danger' style='width: #{total_error}%'></div>"
    return total+total_error < 100

  @click_section = (section_id) ->
    data = AvalonProgress.data[section_id]
    if data.status != 'SUCCEEDED' or data.complete < 100
      window.currentPlayer = null
      $('#player').html('<div id="nojs"></div>')

$(document).ready ->
  AvalonProgress.retrieve(true)
  $('a[data-segment]').bind 'streamswitch', ->
    AvalonProgress.click_section($(this).data('segment'))