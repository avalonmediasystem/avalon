$(document).ready ->
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
    sDom: "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>"
    sWrapper: "dataTables_wrapper form-inline"
    aoColumnDefs: [
      { aTargets: [0], bSortable: false, bSearchable: false }
      { aTargets: [2], sType: 'file-size' }
    ]
