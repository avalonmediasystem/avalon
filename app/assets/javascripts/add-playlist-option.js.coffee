addnew = 'Add new playlist'
select_element = $('#post_playlist_id')
add_success = false

select_element.prepend(new Option(addnew))

getSearchTerm = () ->
  return $('span.select2-search--dropdown input').val()

matchWithNew = (params, data) ->
  term = params.term || ''
  term = term.toLowerCase()
  text = data.text.toLowerCase()
  if (text.includes(addnew.toLowerCase()) || text.includes(term))
    return data
  return null

sortWithNew = (data) ->
  return data.sort((a, b) ->
    if (b.text.trim() == addnew)
      return 1
    if (a.text < b.text || a.text.trim() == addnew)
      return -1
    if (a.text > b.text)
      return 1
    return 0)

formatAddNew = (data) ->
  term = getSearchTerm() || ''
  if (data.text == addnew )
    if (term != '')
      term = addnew + ' "' + term + '"'
    else
      term = addnew
    return '<a>
              <i class="fa fa-plus" aria-hidden="true"></i> <b>'+term+'</b>
            </a>'
  else
    start = data.text.toLowerCase().indexOf(term.toLowerCase())
    if (start != -1)
      end = start+term.length-1
      return data.text.substring(0,start) + '<b>' + data.text.substring(start, end+1) + '</b>' + data.text.substring(end+1)
  return data.text

showNewPlaylistModal = (playlistName) ->
  #set to defaults first
  $('#new_playlist_submit').val('Create')
  $('#new_playlist_submit').prop("disabled", false)
  $('#playlist_title').val(playlistName)
  $('#playlist_comment').val("")
  $('#playlist_visibility_private').prop('checked', true)
  #remove any possible old errors
  $('#title_error').remove()
  $('#playlist_title').parent().removeClass('has-error')
  add_success = false
  #finally show
  $('#add-playlist-modal').modal('show')
  return true

$('#add-playlist-modal').on('hidden.bs.modal', () ->
  if (!add_success)
    op = select_element.children()[1]
    if (op)
      newval = op.value
    else
      newval = -1
    select_element.val(newval).trigger('change.select2')
)

select_element.select2({
  templateResult: formatAddNew
  escapeMarkup:
    (markup) -> return markup
  matcher: matchWithNew
  sorter: sortWithNew
  })
  .on('select2:selecting',
    (evt) ->
      choice = evt.params.args.data.text
      if (choice.indexOf(addnew) != -1)
        showNewPlaylistModal(getSearchTerm())
  )

$('#playlist_form').submit(
  () ->
    if($('#playlist_title').val())
      $('#new_playlist_submit').val('Saving...')
      $('#new_playlist_submit').prop("disabled", true)
      return true
    if($('#title_error').length == 0)
      $('#playlist_title')
        .after('<h5 id="title_error" class="error text-danger">Name is required</h5>')
      $('#playlist_title').parent().addClass('has-error')
    return false
)

$("#playlist_form").bind('ajax:success',
  (event) ->
    [data, status, xhr] = event.detail
    $('#add-playlist-modal').modal('hide')
    if (data.errors)
      console.log(data.errors.title[0])
    else
      add_success = true
      select_element
        .append(new Option(data.title, data.id.toString(), true, true))
        .trigger('change')
  )
