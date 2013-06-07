window.MediaObjectSelectBox =
  class MediaObjectSelectBox
    constructor: (@url, @unitSelections) ->
      $('#collection_media_object_ids').select2
        placeholder: 'Search by name or net id'
        minimumInputLength: 3
        multiple: true
        width: '500px'

        formatSelection: (mediaObject, container) ->

          $(container).empty().append( template )
          template = 
            """
            <div class="thumbnail" style="float: left;">
              <img src="#{mediaObject.thumbnail_url}"/>
            </div>

            <div class="caption">
              <h4>#{mediaObject.text}</h4>
              <div class='span2'>
                <dl class="dl-horizontal">
                  <dt>Main title</dt>
                  <dd>asdfasdf.</dd>
                </dl>
              </div>
              <div class='clearfix'/>
            </div>
            """
          $(container).addClass('inner').append $(template)
          undefined
        formatResult: (mediaObject) ->
          mediaObject.text unless mediaObject.thumbnail_url?
          "<img class='' src='#{mediaObject.thumbnail_url}'/> #{mediaObject.text}"
        initSelection: (element, callback) =>
          callback @unitSelections
        ajax:
          url: @url
          dataType: 'json'
          data: (term, page) ->
            q: term
          results: (data, page) ->
            results:
              data.media_objects