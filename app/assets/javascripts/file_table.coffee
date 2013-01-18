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

  $('#file-list').dataTable
    sDom: "<'row'<'span6'p><'span6'f>r>t>"
    sWrapper: "dataTables_wrapper form-inline"
    aaSorting: [[3, 'desc']]
    aoColumnDefs: [
      { aTargets: [0,4,5], bSortable: false }
      { aTargets: [0,2,4], bSearchable: false }
      { aTargets: [2], sType: 'file-size' }
    ]
    iDisplayLength: 8

