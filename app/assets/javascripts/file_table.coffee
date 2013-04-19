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

$(document).ready ->
  $('.fileupload').fileupload
    name: 'Filedata[]'

  $('.fileupload input:file').change (e) ->
    files = $(e.target.files).map (i,f) -> f.name
    preview = $(e.target).closest('.fileupload').data('fileupload').$preview
    preview.html(files.toArray().join())

  $('.dropbox-trigger').click ->
    $('#dropbox_modal').modal
      backdrop: true,
      keyboard: true
    .addClass('big-modal')

  # a toggle for selecting and deselecting all the items
  # on the current page
  $('#select_deselect_all').click ->
    toggle_val = $(@).is(':checked') ? false : true
    nodes = $('#file-list > tbody > tr') #data_table.fnGetNodes()
    $(nodes).each (index, node) ->
      $(node).find('input[type="checkbox"]').prop 'checked', toggle_val

  # when a user closes the modal the checkboxes should be cleared
  $('#dropbox_modal').on 'hidden', ->
    $('input[type="checkbox"]').prop 'checked', false

  # do an ajax request
  $('.remove-selected-files').click (e) ->
    e.preventDefault()
    window.dropBoxDataTable.remove_selected_files_event(e, @.href)

  $.extend $.fn.dataTableExt.oSort,
    "file-size-pre": (a) ->
      mags =
        KB: 1000
        MB: 1000000
        GB: 1000000000
      x = a.substring(0,a.length - 2)
      unit = a.substring(a.length - 2, a.length)
      x_unit = mags[unit]
      parseInt( x * x_unit, 10 )
    "file-size-asc": (a,b) ->
      ((a < b) ? -1 : ((a > b) ? 1 : 0)) 
    "file-size-desc": (a,b) ->
      ((a < b) ? 1 : ((a > b) ? -1 : 0))

  $.fn.dataTableExt.oStdClasses.sSortColumn = 'sorting_ignore_'

  window.data_table = $('#file-list').dataTable
    sDom: "<'row'<'span6'p><'span6'f>r>t>"
    sWrapper: "dataTables_wrapper form-inline"
    aaSorting: [[3, 'desc']]
    aoColumnDefs: [
      { aTargets: [0,4,5], bSortable: false }
      { aTargets: [0,2,4], bSearchable: false }
      { aTargets: [2], sType: 'file-size' }
    ]
    iDisplayLength: 8
    page: ->
      console.log('pagggging')

window.dropBoxDataTable =

  remove_selected_files_event: (event, url) ->
    nodes = window.data_table.fnGetNodes()

    # using this would select only the rows on the page viewed by the user
    #nodes = $('#file-list > tbody > tr')

    # selected filenames
    filenames = $(nodes).map((i, node) ->
      $(node).find('.name').text() if $(node).find('input[type=\"checkbox\"]').is ':checked'
    )
    if filenames.length > 0
      $('.remove-selected-files').attr('disabled', true)
      filenames_array = filenames.toArray()
      if confirm("Deleted files cannot be recovered. Are you sure?\n-------------------------\n" + filenames_array.join("\n"))
        window.dropBoxDataTable.delete_selected_files_ajax_request(url, filenames_array )
      else
        $('.remove-selected-files').attr('disabled', false)

  delete_selected_files_ajax_request: ( url, filenames ) ->
    $.ajax
      type: 'delete'
      _method: 'delete'
      url: url
      data: { filenames: filenames }
      success: (response) ->
        deleted_filenames = response.deleted_filenames
        if deleted_filenames.length > 0
          $(window.data_table.fnGetNodes()).map (index, row) ->
            name = $(row).find("td.name").text()
            window.data_table.fnDeleteRow( row ) if $.inArray(name, deleted_filenames ) != -1 # this doesn't return a bool (unfortunately)


          # re-enable the submit button once the form is finished
          $('.remove-selected-files').attr('disabled', false)

          # the select all checkbox should be deselected after successfully deleting files
          $('#select_deselect_all').prop 'checked', false
