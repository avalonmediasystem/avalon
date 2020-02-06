# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

timeCodeToSeconds = (hh_mm_ss) ->
  tc_array = hh_mm_ss.split(":").reverse()
  tc_ss = parseInt(tc_array[0])||0
  tc_mm = parseInt(tc_array[1])||0
  tc_hh = parseInt(tc_array[2])||0
  tc_in_seconds = ( tc_hh * 3600 ) + ( tc_mm * 60 ) + tc_ss
  return tc_in_seconds

@enableMarkerEditForm = (event) ->
  button = $(this)
  form = button.closest('form')
  txt = form.find('.marker_title')
  txt.after $('<input type=\'text\' name=\'marker[title]\' style=\'width:100%\' />').val(txt.text())
  txt.hide()
  txt = form.find('.marker_start_time')
  txt.after $('<input type=\'text\' name=\'marker[start_time]\' style=\'width:100%\'/>').val(txt.text())
  txt.hide()
  button.after $('<button type=\'submit\' name=\'marker_edit_save\' class=\'btn btn-default btn-xs\'><i class=\'fa fa-check\' title=\'Save\'></i> <span class=\'sm-hidden\'>Save</span></button>')
  button.hide()
  deleteButton = form.find('button[name="delete_marker"]')
  cancelButton = $('<button type=\'button\' name=\'marker_edit_cancel\' class=\'btn btn-danger btn-xs\'><i class=\'fa fa-times\' title=\'Cancel\'></i> <span class=\'sm-hidden\'>Cancel</span></button>')
  deleteButton.after cancelButton
  cancelButton.click cancelMarkerEdit
  deleteButton.hide()
  return

@disableMarkerEditForm = (id) ->
  row = $('#marker_row_' + id)
  title_input = row.find('input[name = "marker[title]"]')
  title_val = title_input.val()
  title_txt = row.find('.marker_title').text(title_val)
  start_input = row.find('input[name = "marker[start_time]"]')
  offset = timeCodeToSeconds(start_input.val())
  title_txt[0].dataset['offset']=offset
  row[0].dataset['offset']=offset
  title_input.remove()
  title_txt.show()
  start_txt = row.find('.marker_start_time').text(start_input.val())
  start_input.remove()
  start_txt.show()
  button = row.find('#edit_marker_' + id)
  button.show()
  row.find('button[name="marker_edit_save"]').remove()
  row.find('button[name="delete_marker"]').show()
  row.find('button[name="marker_edit_cancel"]').remove()
  offset_percent = if isNaN(parseFloat(offset)) then 0 else Math.min(100,Math.round(100*offset / currentPlayer.media.duration))
  marker_title = String(title_val).replace(/"/g, '&quot;')+' ['+start_input.val()+']'
  $('.scrubber-marker[data-marker="'+id+'"]').css('left',offset_percent+'%').unbind('click').click (e) ->
    currentPlayer.setCurrentTime offset
  marker = $('.mejs-time-float-marker[data-marker="'+id+'"]')
  marker.css('left',offset_percent+'%').find('.mejs-time-float-current-marker').text(marker_title)
  return

@cancelMarkerEdit = (event) ->
  button = $(this)
  form = button.closest('form')
  input = form.find('input[name = "marker[title]"]')
  txt = form.find('.marker_title')
  txt.show()
  input.remove()
  input = form.find('input[name = "marker[start_time]"]')
  txt = form.find('.marker_start_time')
  txt.show()
  input.remove()
  form.find('button[name="edit_marker"]').show()
  form.find('button[name="marker_edit_save"]').remove()
  form.find('button[name="delete_marker"]').show()
  form.find('button[name="marker_edit_cancel"]').remove()
  return

@handle_edit_save = (e, data, status, xhr) ->
  response = $.parseJSON(xhr.responseText)
  if response['action'] == 'destroy'
    #respond to destroy
    $('.scrubber-marker[data-marker="'+response['id']+'"]').remove()
    $('.mejs-time-float-marker[data-marker="'+response['id']+'"]').remove()
    $('#marker_row_' + response['id']).remove()
    if $('.row .marker').length == 0
      $('#markers_heading').remove()
      $('#markers_section').remove()
  else
    #respond to edit
    disableMarkerEditForm response['id']
    $('#marker_item_edit_alert').html("")
  return

@handle_edit_fail = (e, xhr, status, error) ->
  alert = "<div class='alert alert-danger' style='padding:0 10px; margin-bottom: 0;'>";
  alert += "<button type='button' class='close' data-dismiss='alert'>&times;</button>";
  for i in xhr.responseJSON.errors
    alert += "<span>"+i+"</span>"
  alert += "</div>";
  $('#marker_item_edit_alert').html(alert) # need to add this to the correct marker_item_edit_alert element, hardcoded to 2 right now

$('button.edit_marker').click enableMarkerEditForm
$('.marker_title').click (e) ->
  if typeof currentPlayer != typeof undefined
    currentPlayer.setCurrentTime parseFloat(@dataset['offset']) or 0
  return
$('.edit_avalon_marker').on('ajax:success', handle_edit_save).on('ajax:error', handle_edit_fail)
